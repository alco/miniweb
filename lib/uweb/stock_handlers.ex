defmodule MicroWeb.StockHandlers do
  use MicroWeb.Handler

  def static_handler(path, opts, conn) do
    cond do
      filepath=opts[:file] ->
        reply_file(200, filepath)

      rootdir=opts[:root] ->
        reply_file(200, Path.join([rootdir|path]))

      true -> nil
    end
  end
end
