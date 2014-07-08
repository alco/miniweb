defmodule Mix.Tasks.Uweb do
  use Mix.Task

  @shortdoc Miniweb.CLI.Definition.task_help
  @moduledoc """
  #{@shortdoc}

  To find out more, run

      mix uweb
  """
  @cmdspec Miniweb.CLI.Definition.new("mix")

  def run(args), do: Miniweb.CLI.main(args, @cmdspec)
end
