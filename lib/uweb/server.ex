defmodule HttpState do
  @moduledoc false
  defstruct method: nil, uri: "", headers: []
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

    client_loop(sock, req_handler, nil, %HttpState{})
  end

  # The receive loop which waits for a packet from the client, then invokes the
  # handler function and sends its return value back to the client.
  def client_loop(
    sock,
    req_handler,
    state,
    http_state
  ) do
    pid = self()

    :inet.setopts(sock, active: :once)

    receive do
      {:http, ^sock, {:http_request, method, uri, _version}} ->
        #log "#{inspect pid}: got initial request #{method} #{inspect uri}"
        new_http_state = %HttpState{http_state | method: method, uri: uri}
        client_loop(sock, req_handler, state, new_http_state)

      {:http, ^sock, {:http_header, _, field, _reserved, value}} ->
        #log "#{inspect pid}: got header #{field}: #{value}"
        new_http_state = Map.update!(http_state, :headers, &[{field, value}|&1])
        client_loop(sock, req_handler, state, new_http_state)

      {:http, ^sock, :http_eoh} ->
        method = http_state.method
        uri = http_state.uri
        log "#{inspect pid}: processing request #{method} #{inspect uri}"
        if req_handler do
          case handle_req(req_handler, {method, uri}, sock) do
            {:reply, data, _new_state } ->
              length = byte_size(data)
              :gen_tcp.send(sock, "HTTP/1.1 200 OK\r\nContent-Length: #{length}\r\n\r\n#{data}")
              #client_loop(sock, handler, new_state, http_state)
              client_close(sock)

            {:noreply, _new_state } ->
              #client_loop(sock, handler, new_state, http_state)
              client_close(sock)

            {:close, reply} ->
              if reply do
                :gen_tcp.send(sock, reply)
              end
              client_close(sock)
          end
        else
          # Work like a ping server by default
          :gen_tcp.send(sock, "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok")
          #client_loop(sock, handler, state, http_state)
          client_close(sock)
        end

      {:tcp_closed, ^sock} ->
        client_close(sock)

      other ->
        log "Received unhandled message #{inspect other}"
        client_close(sock)
    end
  end

  defp handle_req({:fun, handler}, payload, state), do:
    handler.(payload, state)

  defp handle_req({:module, {mod, opts}}, {method, path}, sock) do
    mod.handle(normalize_method(method), normalize_path(path), opts, sock)
  end

  defp normalize_method(:GET),     do: :get
  defp normalize_method(:HEAD),    do: :head
  defp normalize_method(:POST),    do: :post
  defp normalize_method(:PUT),     do: :put
  defp normalize_method(:DELETE),  do: :delete
  defp normalize_method(:OPTIONS), do: :options
  defp normalize_method(other), do: other


  defp normalize_path(:*), do: ["*"]

  defp normalize_path({:absoluteURI, _proto, _host, _port, path}), do:
    normalize_path(path)

  defp normalize_path({:scheme, scheme, string}), do:
    raise(ArgumentError, message: "No idea about the scheme: #{inspect scheme} #{inspect string}")

  defp normalize_path({:abs_path, path}), do:
    normalize_path(path)

  defp normalize_path(path) when is_binary(path) do
    #IO.puts "INCOMING PATH: #{inspect path}"
    {path, _query} = case String.split(path, "?", global: false) do
      [path, query] -> {path, query}
      [path]        -> {path, nil}
    end

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
