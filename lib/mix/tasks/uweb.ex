defmodule Mix.Tasks.Uweb do
  use Mix.Task

  @shortdoc Miniweb.CLI.task_help
  @moduledoc """
  #{@shortdoc}

  To find out more, run

      mix uweb
  """

  def run(args), do: Miniweb.CLI.main(args)
end
