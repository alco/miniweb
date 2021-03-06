defmodule Router do
  use Muweb.Router

  import Miniweb.Handlers


  mount "/api", Elixir.APIRouter

  handle "/", [:head, :get], &static_handler,
    file: Path.join(param(:root_dir), "index.html")

  handle _,   [:head, :get], &static_handler,
    root: param(:root_dir)

  handle _, _, do: ireply("Forbidden")
end


defmodule APIRouter do
  use Muweb.Router

  handle "/", :post do
    ireply(201)
  end

  handle "/random", :get, wrap(Util.random, [])

  handle "/random_int", :get do
    min = iquery("min", "0") |> String.to_integer
    max = iquery("max", "1000000") |> String.to_integer
    ireply(200, Util.random(min, max) |> to_string)
  end

  handle _, _ do
    ireply(403)
  end
end


defmodule Util do
  def random() do
    :random.uniform()
  end

  def random(min, max) when max >= min do
    :random.uniform(1 + max - min) + min - 1
  end

  def random(_, _), do: :bad_range
end


router = Router.init(root_dir: "example/priv/static")
Muweb.Server.start_link(router: router, log_enabled: true)
