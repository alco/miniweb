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
   action: &MuWeb.CLI.cmd_inspect/2,
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
   action: &MuWeb.CLI.cmd_proxy/2,
   arguments: [[name: "url", help: "URL to connect to."]],
   help: """
     Work as a tunnelling proxy, logging all communications. All traffic
     between client and remote server is transmitted without alterations, but
     all requests and responses are logged to stdout.
     """,
  ],

  [name: "serve",
   action: &MuWeb.CLI.cmd_serve/2,
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

defmodule MuWeb.CLI do
  alias Commando.Cmd

  @help "Single task encapsulating a set of useful commands that utilise the μWeb server."

  def task_help, do: @help

  @cmdspec Commando.new [
    prefix: "mix", name: "muweb",
    version: "μWeb #{Mix.Project.config[:version]}",

    help: @help, options: options, commands: commands,
  ]

  def main(args), do: Commando.parse(args, @cmdspec)

  def cmd_inspect(%Cmd{options: cmd_opts}, %Cmd{options: opts}) do
    MuWeb.CLI.Inspect.run(opts[:port], cmd_opts[:reply_file])
  end

  def cmd_proxy(%Cmd{arguments: %{"url" => url}}, %Cmd{options: opts}) do
    MuWeb.CLI.Proxy.run(url, opts[:port])
  end

  def cmd_serve(%Cmd{arguments: %{"path" => dir}, options: cmd_opts},
                %Cmd{options: opts})
  do
    case dir do
      "." -> IO.puts "Serving current directory"
      _   -> IO.puts "Serving directory: #{dir}"
    end
    MuWeb.CLI.Serve.run(dir, opts[:port], cmd_opts[:list])
  end
end
