defmodule MicroWeb.NotAllowedHandler do
  use MicroWeb.Handler

  def handle(_path, _opts) do
    reply(405)
  end
end
