defmodule Mix.Tasks.Muweb do
  @shortdoc "Run μWeb commands"

  @moduledoc """
  Synopsis:
    mix muweb [OPTIONS] COMMAND [ARG...]

  Single task encapsulating a set of useful commands
  that utilise the μWeb server.

  Options (available for all commands except "help"):
    -h, --host
        Hostname to resolve. Accepts extended format with port, e.g.
        "localhost:4000".

    -p, --port
        Port number to listen on.

  Commands:
    help       Display help for a command
    inspect    Log all incoming requests to stdout
    proxy      Work as a tunnelling proxy, logging all communications
    serve      Serve files from a given directory
  """

  use Mix.Task


  def run([]), do: usage()

  def run(args) do
    case OptionParser.parse_head(args, aliases: [p: :port, h: :host]) do
      {_, _, [h|_]} ->
        IO.puts "Unrecognized option -#{h}"

      {_, [], []} ->
        usage()

      {opts, [cmd|rest], []} ->
        IO.puts "Applying opts #{inspect opts}"
        run_cmd(cmd, rest)
    end
  end


  def run_cmd("help", []),    do: usage()
  def run_cmd("help", [cmd]), do: usage(cmd)


  def run_cmd("inspect", args) do
    # mix muweb [OPTIONS] inspect [-f PATH|--reply-file=PATH]
    case OptionParser.parse(args, aliases: [f: :reply_file]) do
      {_, _, [h|_]} ->
        IO.puts "Unrecognized option -#{h}"

      {_opts, [], []} ->
        IO.puts "inspecting..."

      _ -> usage("inspect")
    end
  end


  def run_cmd("serve", []) do
    IO.puts "Serving current directory..."
    serve(".")
  end

  def run_cmd("serve", [path]) do
    IO.puts "Serving path #{path}..."
    serve(path)
  end


  def run_cmd(cmd, args), do: (IO.inspect args; usage(cmd))

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

    Display description of the given command.
    """
  end

  defp usage("inspect") do
    Mix.shell.info """
    Synopsis:
      mix muweb [OPTIONS] inspect [-f PATH|--reply-file=PATH]

    Log incoming requests to stdout, optionally sending a reply back.

    Options:
      -f PATH, --reply-file=PATH
         Send the contents of file at PATH in reponse to incoming requests.

         By default, nothing is sent in response, the connection is closed
         immediately.

         Passing a dash (-) for PATH will read from stdin.
    """
  end

  defp usage("proxy") do
    Mix.shell.info """
    Synopsis:
      mix muweb [OPTIONS] proxy

    Work as a proxy, transmiting all traffic between client and remote server
    without alterations, but logging all requests and responses to stdout.
    """
  end

  defp usage("serve") do
    Mix.shell.info """
    Synopsis:
      mix muweb [OPTIONS] serve [-l|--list] [PATH]

    Serve files from the specified directory, recursively.

    Arguments:
      PATH
          The directory to serve (default: .).

    Options:
      -l, --list
          For directory requests, serve HTML with the list of contents of that
          directory.

          Without this option, "403 Forbidden" is returned for
          directory requests.
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
