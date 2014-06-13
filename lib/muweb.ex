defmodule MuWeb do
  @moduledoc false

  use Application.Behaviour

  def start(_type, _args) do
    MuWeb.Supervisor.start_link
  end
end
