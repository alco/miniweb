defmodule HttpReq do
  defstruct [
    method: nil,
    path: "",
    query: "",
    headers: [],
    proto: nil,
    version: nil,
    body: "",
  ]
end

defmodule MicroWeb.Server do
  @moduledoc """
  An http server that allows users to set up handlers to process data coming
  from the clients.
  """


  defp log(msg) do
    IO.puts "[uweb] " <> msg
  end

  @port 9000


  @doc """
  Starts the server. Available options:

    * port    -- port number listen on
    * router  -- a module that implements the router API
                 (will be used instead of handler if provided)
    * handler -- a function of one argument

  """
  def start(options \\ []) do
    port = Keyword.get(options, :port, @port)
    case :gen_tcp.listen(port, [{:packet, :http_bin}, {:active, false}, {:reuseaddr, true}]) do
      {:ok, sock} ->
        log "Listening on port #{port}..."
        accept_loop(sock, options)

      {:error, reason} ->
        log "Error starting the server: #{reason}"
    end
  end

  # Function responsible for spawning new processes to handle incoming
  # requests.
  defp accept_loop(sock, options) do
    case :gen_tcp.accept(sock) do
      {:ok, client_sock} ->
        spawn_client(client_sock, options)
        accept_loop(sock, options)

      {:error, reason} ->
        log "Failed to accept on socket: #{reason}"
    end
  end

  # Spawn a new process to handle communication over the socket.
  defp spawn_client(sock, options) do
    if handler = options[:handler], do: req_handler = {:fun, handler}
    if router = options[:router], do: req_handler = {:module, router}

    pid = spawn(fn -> client_start(sock, req_handler) end)
    :ok = :gen_tcp.controlling_process(sock, pid)
  end

  defp client_start(sock, req_handler) do
    pid = self()

    # Get info about the client
    case :inet.peername(sock) do
      {:ok, {address, port}} ->
        log "#{inspect pid}: got connection from a client: #{inspect address}:#{inspect port}"

      {:error, reason} ->
        log "#{inspect pid}: got connection from an unknown client (#{reason})"
    end

    :random.seed(:erlang.now())

    client_loop(sock, req_handler, %HttpReq{})
  end

  # The receive loop which waits for a packet from the client, then invokes the
  # handler function and sends its return value back to the client.
  def client_loop(
    sock,
    req_handler,
    req
  ) do
    pid = self()

    :inet.setopts(sock, active: :once)

    receive do
      {:http, ^sock, {:http_request, method, uri, version}} ->
        :inet.setopts(sock, [:binary, {:packet, :httph_bin}, {:active, :once}])
        log "#{inspect pid}: got initial request #{method} #{inspect uri}"
        {path, query} = split_uri(uri)
        updated_req = %HttpReq{req | method: method,
                                       path: path,
                                      query: query,
                                    version: version}
        client_loop(sock, req_handler, updated_req)

      {:http, ^sock, {:http_header, _, field, _reserved, value}} ->
        log "#{inspect pid}: got header #{field}: #{value}"
        updated_req = Map.update!(req, :headers, &[{to_string(field), value}|&1])
        client_loop(sock, req_handler, updated_req)

      {:http, ^sock, :http_eoh} ->
        :inet.setopts(sock, [:binary, {:packet, :raw}, {:active, false}])
        data = read_request_data(sock, req.headers)
        if req_handler do
          log "#{inspect pid}: processing request #{req.method} #{req.path}"
          updated_req = %HttpReq{req | body: data}
          format_req(updated_req)
          updated_req = %HttpReq{req | method: normalize_method(req.method)}
          case handle_req(req_handler, updated_req, sock) do
            {:reply, data} ->
              length = byte_size(data)
              :gen_tcp.send(sock, "HTTP/1.1 200 OK\r\nContent-Length: #{length}\r\n\r\n#{data}")
              client_close(sock)

            :noreply ->
              client_close(sock)
          end
        else
          :gen_tcp.send(sock, "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok")
          client_close(sock)
        end

      {:http, ^sock, {:http_error, error_line}} ->
        log "#{inspect pid}: HTTP error on line: #{error_line}"
        client_close(sock)

      {:tcp_closed, ^sock} ->
        client_close(sock)

      other ->
        log "Received unhandled message #{inspect other}"
        client_close(sock)
    end
  end


  defp read_request_data(sock, headers) do
    #IO.inspect http_state.headers
    length_header = Enum.find(headers, fn {header, _} ->
      header == "Content-Length"
    end)
    content_length = case length_header do
      {_, val} -> binary_to_integer(val)
      _        -> 0
    end
    #IO.inspect sock
    #IO.inspect content_length
    case :gen_tcp.recv(sock, content_length) do
      {:ok, data} -> data
      {:error, reason} -> raise RuntimeError, 'Could not read request data: #{inspect reason}'
    end
  end


  defp format_req(%HttpReq{}=req) do
    query = if (q = req.query; byte_size(q) > 0) do
      "?" <> q
    else
      ""
    end
    IO.puts "#{req.method} #{req.path}#{query} HTTP/#{format_version(req.version)}"
    Enum.each(req.headers, fn {key, val} ->
      IO.puts "#{key}: #{val}"
    end)
    IO.puts ""
    IO.puts req.body
  end

  defp format_version({major, minor}), do: "#{major}.#{minor}"


  defp handle_req({:fun, handler}, req, sock), do:
    handler.(req, sock)

  defp handle_req({:module, {mod, opts}}, %HttpReq{method: method, path: path}=req, sock) do
    mod.handle(method, split_path(path), req, opts, sock)
  end

  defp normalize_method(:GET),     do: :get
  defp normalize_method(:HEAD),    do: :head
  defp normalize_method(:POST),    do: :post
  defp normalize_method(:PUT),     do: :put
  defp normalize_method(:DELETE),  do: :delete
  defp normalize_method(:OPTIONS), do: :options
  defp normalize_method(other), do: other


  defp split_uri(:*), do: {"*", ""}

  defp split_uri({:absoluteURI, _proto, _host, _port, qpath}), do:
    split_uri(qpath)

  defp split_uri({:scheme, scheme, string}), do:
    raise(ArgumentError, message: 'No idea about the scheme: #{inspect scheme} #{inspect string}')

  defp split_uri({:abs_path, qpath}), do:
    split_uri(qpath)

  defp split_uri(qpath) do
    case String.split(qpath, "?", global: false) do
      [path, query] -> {path, query}
      [path]        -> {path, ""}
    end
  end


  defp split_path("*"), do: ["*"]

  defp split_path(path) when is_binary(path) do
    #IO.puts "INCOMING PATH: #{inspect path}"
    String.split(path, "/")
    |> MicroWeb.Util.strip_list()
    #|> IO.inspect
  end


  defp client_close(sock) do
    log "#{inspect self()}: closing connection"
    :gen_tcp.close(sock)
  end


  def send(sock, data) do
    :gen_tcp.send(sock, data)
  end
end
