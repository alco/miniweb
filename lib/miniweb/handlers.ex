defmodule Miniweb.Handlers do
  import Muweb.Handler

  alias Muweb.Server

  def inspect_handler(_path, opts, req) do
    IO.puts Server.format_req(req)

    case opts[:reply] do
      nil -> close(req)
      {:data, data} -> reply(req, 200, data)
      path -> reply_file(req, 200, path)
    end
  end

  def static_handler(path, opts, req) do
    cond do
      filepath=opts[:file] ->
        reply_file(req, 200, filepath)

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
              reply(req, status, data)
            else
              reply(req, 403, "Forbidden")
            end

          {:ok, _} -> reply_file(req, 200, fullpath)

          _ -> reply(req, 404, "Not Found")
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
