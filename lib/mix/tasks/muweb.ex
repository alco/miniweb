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
     [name: [:list, :l],
      help: """
        For directory requests, serve HTML with the list of files in that directory.

        Without this option, "403 Forbidden" is returned for directory requests.
        """],
   ],
  ],
]

spec = Commando.new [
  prefix: "mix",
  name: "muweb",
  version: "μWeb #{Mix.Project.config[:version]}",

  help: "Single task encapsulating a set of useful commands that utilise the μWeb server.",

  options: options,
  commands: commands,
]

defmodule Mix.Tasks.Muweb do
  @cmdspec spec

  @shortdoc "Run μWeb commands"
  @moduledoc Commando.help(spec)

  use Mix.Task

  def run(args) do
    {:ok, %Commando.Cmd{options: opts, subcmd: cmd}} =
      Commando.parse(args, @cmdspec)
    run_cmd(cmd.name, cmd, opts)
  end

  def run_cmd("inspect", _cmd, _options) do
    IO.puts "inspecting..."
    #_ -> nil #usage("inspect")
  end

  def run_cmd("proxy", _cmd, _options) do
    IO.puts "proxying..."
  end

  def run_cmd("serve", %Commando.Cmd{arguments: %{"path" => dir}}, options) do
    IO.puts "Serving directory: #{dir}"
    serve(dir, options[:port])
  end

  ###

  defmodule ServeRouter do
    @moduledoc false
    use MuWeb.Router
    params [:root_dir]
    handle _, [:get, :head], &MuWeb.StockHandlers.static_handler, root: param(:root_dir)
  end

  defp serve(path, port) do
    router = ServeRouter.init(root_dir: path)
    MuWeb.Server.start(router: router, port: port)
  end
end
