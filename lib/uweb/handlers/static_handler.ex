defmodule MicroWeb.StaticHandler do
  use MicroWeb.Handler

  def handle(path, opts) do
    #IO.inspect path
    cond do
      filepath=opts[:file] ->
        reply_file(200, filepath)

      rootdir=opts[:root] ->
        reply_file(200, Path.join([rootdir|path]))

      true -> nil
    end
  end
end
