defmodule Miniweb.CLI.Proxy do
  defmodule Router do
    @moduledoc false
    use Muweb.Router
    import Miniweb.Handlers
    params [:location, :filter]
    handle _, _, &proxy_handler, location: param(:location), filter: param(:filter)
  end

  def run(url, filter, port) do
    router = Router.init(location: url, filter: filter)
    Muweb.Server.start(router: router, port: port)
  end
end
