defmodule MicroWebExample.Router do
  use MicroWeb.Router

  handle "/",
         :get,
         MicroWeb.StaticHandler,
         file: "example/priv/static/index.html"

  handle "/api/...",
         [:get, :post],
         MicroWebExample.APIHandler

  handle _, :get, MicroWeb.StaticHandler, root: "example/priv/static"
  handle _,    _, MicroWeb.NotAllowedHandler
end


defmodule MicroWebExample.APIHandler do
  use MicroWeb.Handler

  def handle(_path, _opts) do
    #reply(200, content |> to_json)
    #reply_file(200, path)
  end
end


MicroWeb.Server.start(router: MicroWebExample.Router)
