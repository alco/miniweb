options = [
  :version,

  [name: [:host, :h], argname: "hostname",
   help: "Hostname to listen on."],

  [name: [:port, :p], argtype: :integer, default: 9000,
   help: "Port number to listen on."],

  [name: [:debug, :d], argtype: :boolean,
   help: "Print debug info."],
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

help = "Single task encapsulating a set of useful commands that utilise the μWeb server."

defmodule Miniweb.CLI.Definition do
  @help help
  @options options
  @commands commands

  def new(prefix) do
    Commando.new [
      prefix: prefix, name: "uweb",
      version: "μWeb #{Mix.Project.config[:version]}",

      help: @help, options: @options, commands: @commands,
    ]
  end

  def task_help, do: @help
end

defmodule Miniweb.CLI do
  alias Commando.Cmd

  @cmdspec Miniweb.CLI.Definition.new("")

  def start() do
    Enum.map(:init.get_plain_arguments, &List.to_string/1)
    |> main()
  end

  def main(args, spec \\ @cmdspec), do: Commando.exec(args, spec, actions: [
    commands: %{
      "inspect" => &cmd_inspect/2,
      "serve"   => &cmd_serve/2,
    }
  ])

  defp cmd_inspect(%Cmd{options: cmd_opts}, %Cmd{options: opts}) do
    unless check_debug(opts) do
      IO.puts "Listening on port #{opts[:port]}"
    end
    Miniweb.CLI.Inspect.run(opts[:port], cmd_opts[:reply_file])
  end

  defp cmd_serve(%Cmd{arguments: %{"path" => dir}, options: cmd_opts},
                %Cmd{options: opts})
  do
    case dir do
      "." -> IO.write "Serving current directory "
      _   -> IO.write "Serving directory: #{dir} "
    end
    if check_debug(opts) do
      IO.puts ""
    else
      IO.puts "on port #{opts[:port]}"
    end
    Miniweb.CLI.Serve.run(dir, opts[:port], cmd_opts[:list])
  end

  defp check_debug(opts) do
    if opts[:debug] do
      Application.put_env(:muweb, :dbg_log_enabled, true)
      true
    end
  end
end
