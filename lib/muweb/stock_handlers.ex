defmodule MuWeb.StockHandlers do
  use MuWeb.Handler

  alias MuWeb.Server

  def inspect_handler(_path, opts, conn, req) do
    IO.puts Server.format_req(req)

    case opts[:reply] do
      nil -> abort()
      {:data, data} -> reply(200, data)
      path -> reply_file(200, path)
    end
  end

  def proxy_handler(_path, opts, conn, req) do
    remote_host = opts[:location]
    #IO.inspect path
    #IO.inspect remote_host
    #abort()

    # TODO:
    # - send request to remote host
    # - log reply
    {address, port} =
      case String.split(remote_host, ":") do
        [address, port] -> {address, String.to_integer(port)}
        [address] -> {address, 80}
      end
    {:ok, sock} = :gen_tcp.connect(String.to_char_list(address), port, [{:packet, :http_bin}, {:active, :once}])

    req = Map.update!(req, :headers, fn headers ->
      Enum.map(headers, fn
        {"Host", _}=x ->
          IO.inspect x
          {"Host", remote_host}
        other -> other
      end)
    end)

    Server.send(sock, Server.format_req(req))
    Server.spawn_client(sock, handler: &handle_proxy_response/3, state: conn)
    :noclose
  end

  defp handle_proxy_response(req, _sock, old_sock) do
    response = Server.format_req(req)
    IO.write response
    :gen_tcp.send(old_sock, response)
    :noreply
  end

  def static_handler(path, opts, conn, req) do
    cond do
      filepath=opts[:file] ->
        reply_file(200, filepath)

      rootdir=opts[:root] ->
        fullpath = Path.join([rootdir|path])
        displaypath = case path do
          [] -> "/"
          _  -> Path.join(["/"|path])
        end
        case File.stat(fullpath) do
          {:ok, %File.Stat{type: :directory}} ->
            if opts[:listdir] do
              {status, data} = build_directory_listing(fullpath, displaypath)
              reply(status, data)
            else
              reply(403, "Forbidden")
            end

          {:ok, _} -> reply_file(200, fullpath)

          _ -> reply(404, "Not Found")
        end

      true -> nil
    end
  end

  defp build_directory_listing(fullpath, displaypath) do
    case File.ls(fullpath) do
      {:ok, files} ->
        list_items = Enum.map(files, fn filename ->
          href = Path.join(displaypath, filename)
          {href, filename}
        end)

        if displaypath != "/" do
          up = {Path.expand(Path.join(displaypath, "..")), ".."}
          list_items = [up|list_items]
        end

        list_str =
          list_items
          |> Enum.map(fn {href, path} ->
            ~s'<li><a href="#{href}">#{path}</a></li>'
          end)
          |> Enum.join("\n")

        data = """
          <html>
            <head>
              <title>Listing of #{displaypath}</title>
            </head>
            <body>
              <ul>#{list_str}</ul>
            </body>
          </html>
          """
        {200, data}

      _ -> {404, nil}
    end
  end
end
