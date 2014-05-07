defmodule MicroWebExample do
  use MicroWeb.Router

  handle "/",
         :get,
         MicroWeb.StaticHandler,
         file: "priv/static/index.html"

  handle "/api/*",
         [:get, :post],
         MicroWebExample.APIHandler

  handle _, :get, MicroWeb.StaticHandler, root: "priv/static"
  handle _,    _, MicroWeb.MethodNotAllowedHandler
end

defmodule MicroWebExample.APIHandler do
  use MicroWeb.Handler

  def handle(...) do
    reply(200, content |> to_json)
    #reply_file(200, path)
  end
end
