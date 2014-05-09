defmodule Mix.Tasks.Uweb do
  @moduledoc """
  Single task encapsulating a set of useful commands.

  Synopsis:
    mix uweb COMMAND [ARG...]

  Commands:
    help       Show help about given command
    inspect    Log all incoming requests to stdout
    proxy      Work as a tunnelling proxy, logging all communications
    serve      Serve files from the given path (default: .)
  """

  use Mix.Task


  def run([]), do: usage


  def run(["help"]), do: usage
  def run(["help", cmd]), do: usage(cmd)


  def run(["inspect"]) do
    IO.puts "inspecting..."
  end


  def run(["serve"]) do
    IO.puts "Serving current directory..."
    serve(".")
  end

  def run(["serve", path]) do
    IO.puts "Serving path #{path}..."
    serve(path)
  end


  def run([cmd|_]), do: usage(cmd)
  def run(_), do: usage

  ###

  defp usage do
    case __info__(:moduledoc) do
      {_, binary} when is_binary(binary) ->
        Mix.shell.info binary

      _ -> Mix.shell.info "#{inspect __MODULE__} was not compiled with docs"
    end
  end

  defp usage("help") do
    Mix.shell.info """
    Synopsis:
      mix uweb help [COMMAND]
    """
  end

  defp usage("inspect") do
    Mix.shell.info """
    Synopsis:
      mix uweb inspect
    """
  end

  defp usage("proxy") do
    Mix.shell.info """
    Synopsis:
      mix uweb proxy
    """
  end

  defp usage("serve") do
    Mix.shell.info """
    Synopsis:
      mix uweb serve [-d] [PATH]

    Arguments:
      PATH    the directory to serve

    Options:
      -d      serve HTML file with directory contents for directory requests
              (by default, directory requests respond with 403 Forbidden)
    """
  end

  defp usage(_), do: usage

  ###

  defmodule ServeRouter do
    @moduledoc false
    use MicroWeb.Router
    handle _, [:get, :head], &MicroWeb.StockHandlers.static_handler, root: param(:root_dir)
  end

  defp serve(path) do
    router = ServeRouter.init(root_dir: path)
    MicroWeb.Server.start(router: router)
  end
end
