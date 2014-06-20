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
   arguments: [
     [name: "url", help: "URL to connect to.", default: nil]
   ],
   options: [
     [name: [:filter, :f], help: "Choose a filter to be applied to requests and responses."],
   ],
   help: """
     Work as a tunnelling proxy, logging all communications. All traffic
     between client and remote server is transmitted without alterations, but
     all requests and responses are logged to stdout.

     When a URL is specified, uWeb will establish a connection with the remote
     host and will also listen on a local port. Any requests sent to it will be
     transmitted to the remote host and any responses will be returned to the
     client.

     When no URL is specified, uWeb will simply listen on a local port, so it
     can be used as a proxy.
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
end

defmodule Miniweb.CLI do
  alias Commando.Cmd

  @help help
  def task_help, do: @help

  @cmdspec Miniweb.CLI.Definition.new("")

  def main(args, spec \\ @cmdspec), do: Commando.exec(args, spec, actions: [
    commands: %{
      "inspect" => &cmd_inspect/2,
      "proxy"   => &cmd_proxy/2,
      "serve"   => &cmd_serve/2,
    }
  ])

  defp cmd_inspect(%Cmd{options: cmd_opts}, %Cmd{options: opts}) do
    Miniweb.CLI.Inspect.run(opts[:port], cmd_opts[:reply_file])
  end

  defp cmd_proxy(%Cmd{arguments: %{"url" => url}, options: cmd_opts}, %Cmd{options: opts}) do
    Miniweb.CLI.Proxy.run(url, cmd_opts[:filter], opts[:port])
  end

  defp cmd_serve(%Cmd{arguments: %{"path" => dir}, options: cmd_opts},
                %Cmd{options: opts})
  do
    case dir do
      "." -> IO.puts "Serving current directory"
      _   -> IO.puts "Serving directory: #{dir}"
    end
    Miniweb.CLI.Serve.run(dir, opts[:port], cmd_opts[:list])
  end
end
