defmodule MuWeb.StockHandlers do
  use MuWeb.Handler

  def static_handler(path, opts, conn) do
    # Check if it's a head request
    # Fixme deal with directories
    cond do
      filepath=opts[:file] ->
        reply_file(200, filepath)

      rootdir=opts[:root] ->
        reply_file(200, Path.join([rootdir|path]))

      true -> nil
    end
  end
end
