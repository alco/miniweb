options = [
  :version,

  [name: [:host, :h], argname: "hostname",
   help: "Hostname to listen on."],

  [name: [:port, :p], argtype: :integer, default: 9000,
   help: "Port number to listen on."],
]

commands = [
  :help,

  [name: "inspect",
   help: "Log incoming requests to stdout, optionally sending a reply back.",
   options: [
     [name: [:reply_file, :f], argname: "path",
      help: """
        Send the contents of file at PATH in response to incoming requests.

        By default, nothing is sent in response, the connection is closed immediately.

        Passing a dash (-) for <path> will read from stdin.
        """],
   ],
  ],

  [name: "proxy",
   help: """
     Work as a tunnelling proxy, logging all communications. All traffic
     between client and remote server is transmitted without alterations, but
     all requests and responses are logged to stdout.
     """,
  ],

  [name: "serve",
   help: "Serve files from the specified directory, recursively.",
   arguments: [[name: "path", default: "."]],
   options: [
     [name: [:list, :l], argtype: :boolean,
      help: """
        For directory requests, serve HTML with the list of files in that directory.

        Without this option, "403 Forbidden" is returned for directory requests.
        """],
   ],
  ],
]

task_help = "Single task encapsulating a set of useful commands that utilise the μWeb server."

defmodule Mix.Tasks.Muweb do
  @shortdoc task_help
  @moduledoc """
  #{task_help}

  To find out more, run

      mix muweb help

  """

  @cmdspec Commando.new [
    prefix: "mix",
    name: "muweb",
    version: "μWeb #{Mix.Project.config[:version]}",

    help: task_help,
    options: options,
    commands: commands,
  ]

  use Mix.Task
  alias Commando.Cmd

  def run(args) do
    {:ok, %Cmd{options: opts, subcmd: cmd}} = Commando.parse(args, @cmdspec)
    run_cmd(cmd.name, cmd, opts)
  end

  def run_cmd("inspect", %Cmd{options: opts}, options) do
    muweb_inspect(options[:port], opts[:reply_file])
  end

  def run_cmd("proxy", _cmd, _options) do
    IO.puts "proxying..."
  end

  def run_cmd("serve", %Cmd{options: opts, arguments: %{"path" => dir}}, options) do
    case dir do
      "." -> IO.puts "Serving current directory"
      _   -> IO.puts "Serving directory: #{dir}"
    end
    muweb_serve(dir, options[:port], opts[:list])
  end

  ###

  alias MuWeb.Router
  alias MuWeb.Server
  import MuWeb.StockHandlers

  defmodule ServeRouter do
    @moduledoc false
    use Router
    params [:root_dir, :listdir]
    handle _, [:get, :head], &static_handler,
                                root: param(:root_dir), listdir: param(:listdir)
  end

  defp muweb_serve(path, port, listdir) do
    router = ServeRouter.init(root_dir: path, listdir: listdir)
    Server.start(router: router, port: port)
  end

  ###

  defmodule InspectRouter do
    @moduledoc false
    use Router
    params [:reply]
    handle _, _, &inspect_handler, reply: param(:reply)
  end

  defp muweb_inspect(port, reply_file) do
    reply = case reply_file do
      nil -> nil
      "-" ->
        IO.puts "Enter the data to be used in responses:"
        {:data, Enum.into(IO.binstream(:stdio, :line), "")}
      path ->
        case File.stat(path) do
          {:error, :enoent} ->
            IO.puts "File not found: #{path}"
            System.halt(1)
          {:ok, %File.Stat{type: :directory}} ->
            IO.puts "#{path} is a directory"
            System.halt(1)
          {:ok, _} -> path
        end
    end
    router = InspectRouter.init(reply: reply)
    Server.start(router: router, port: port)
  end
end
