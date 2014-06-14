defmodule MuWeb.CLI.Serve do
  defmodule Router do
    @moduledoc false
    use MuWeb.Router
    params [:root_dir, :listdir]
    handle _, [:get, :head], &static_handler,
                                root: param(:root_dir), listdir: param(:listdir)
  end

  def run(path, port, listdir) do
    router = Router.init(root_dir: path, listdir: listdir)
    MuWeb.Server.start(router: router, port: port)
  end
end
