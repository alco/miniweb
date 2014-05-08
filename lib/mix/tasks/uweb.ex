defmodule Mix.Tasks.Uweb do
  use Mix.Task

  @shortdoc "List uweb tasks"

  @moduledoc "This is a uweb task"

  def run([]), do: usage


  def run(["serve"]) do
    IO.puts "Serving current directory..."
  end

  def run(["serve", path]) do
    IO.puts "Serving path #{path}..."
  end


  def run(["inspect"]) do
    IO.puts "inspecting..."
  end


  def run(["help"]), do: usage
  def run(["help", cmd]), do: usage(cmd)


  def run([cmd|_]), do: usage(cmd)
  def run(_), do: usage


  defp usage do
    Mix.shell.info """
    Synopsis:
      mix uweb COMMAND [ARG...]

    Commands:
      serve      Serve files from the given path (default: .)
      inspect    Log all incoming requests to stdout
      help       Show help about given command
    """
  end

  defp usage("serve") do
    Mix.shell.info """
    Synopsis:
      mix uweb serve [PATH]

    Arguments:
      PATH    the directory to serve
    """
  end

  defp usage("inspect") do
    Mix.shell.info """
    Synopsis:
      mix uweb inspect
    """
  end

  defp usage("help") do
    Mix.shell.info """
    Synopsis:
      mix uweb help [COMMAND]
    """
  end

  defp usage(_), do: usage
end
