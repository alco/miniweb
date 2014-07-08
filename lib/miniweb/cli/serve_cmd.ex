defmodule Miniweb.CLI.Serve do
  defmodule Router do
    @moduledoc false
    use Muweb.Router
    import Miniweb.Handlers
    handle _, [:get, :head], &static_handler,
                                root: param(:root_dir), listdir: param(:listdir)
  end

  def run(path, port, listdir) do
    router = Router.init(root_dir: path, listdir: listdir)
    Muweb.Server.start_link(router: router, port: port)
  end
end
