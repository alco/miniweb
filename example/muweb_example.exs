defmodule Router do
  use MuWeb.Router

  import MuWeb.StockHandlers

  params [:root_dir]


  mount "/api", Elixir.APIRouter

  handle "/", [:head, :get], &static_handler,
    file: Path.join(param(:root_dir), "index.html")

  handle _,   [:head, :get], &static_handler,
    root: param(:root_dir)

  handle _, _, do: reply("Forbidden")
end


defmodule APIRouter do
  use MuWeb.Router

  handle "/", :post do
    reply(201)
  end

  handle "/random", :get,
    wrap(Util.random,
         [query("min", 0), query("max", 100)],
         status: 200)

  #handle "/random_int", :get do
    #min = query("min", 0)
    #max = query("max", 0)
    #reply(200, Util.random(min, max))
  #end

  handle _, _ do
    reply(403)
  end
end


defmodule Util do
  def random(_min, _max) do
    :random.uniform()
  end
end


router = Router.init(root_dir: "example/priv/static")
MuWeb.Server.start(router: router)
