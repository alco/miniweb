defmodule Mix.Tasks.Muweb do
  @shortdoc "Run μWeb commands"

  @moduledoc """
  Single task encapsulating a set of useful commands
  that utilise the μWeb server.

  Synopsis:
    mix muweb COMMAND [ARG...]

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
      mix muweb help [COMMAND]
    """
  end

  defp usage("inspect") do
    Mix.shell.info """
    Synopsis:
      mix muweb inspect
    """
  end

  defp usage("proxy") do
    Mix.shell.info """
    Synopsis:
      mix muweb proxy
    """
  end

  defp usage("serve") do
    Mix.shell.info """
    Synopsis:
      mix muweb serve [-d] [PATH]

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
    use MuWeb.Router
    handle _, [:get, :head], &MuWeb.StockHandlers.static_handler, root: param(:root_dir)
  end

  defp serve(path) do
    router = ServeRouter.init(root_dir: path)
    MuWeb.Server.start(router: router)
  end
end
