defmodule MuWeb.CLI.Proxy do
  defmodule Router do
    @moduledoc false
    use MuWeb.Router
    params [:locations]
    handle _, _, &proxy_handler, location: param(:location)
  end

  def run(url, port) do
    router = Router.init(location: url)
    MuWeb.Server.start(router: router, port: port)
  end
end
