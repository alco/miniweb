defmodule MuWeb.CLI.Proxy do
  defmodule Router do
    @moduledoc false
    use MuWeb.Router
    params [:location, :filter]
    handle _, _, &proxy_handler, location: param(:location), filter: param(:filter)
  end

  def run(url, filter, port) do
    router = Router.init(location: url, filter: filter)
    MuWeb.Server.start(router: router, port: port)
  end
end
