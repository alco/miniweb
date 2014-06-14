defmodule Mix.Tasks.Muweb do
  use Mix.Task

  @shortdoc MuWeb.CLI.task_help
  @moduledoc """
  #{@shortdoc}

  To find out more, run

      mix muweb help
  """

  def run(args), do: MuWeb.CLI.main(args)
end
