defmodule MuWeb.StockHandlers do
  use MuWeb.Handler

  def inspect_handler(_path, _opts, conn, req) do
    IO.puts MuWeb.Server.format_req(req)
    abort()
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
