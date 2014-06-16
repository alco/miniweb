defmodule MuWeb.CLI.DSL do
  @moduledoc """
  Single task encapsulating a set of useful commands that utilise the μWeb server.
  """

  @prefix "mix"
  @name "muweb"
  @version "μWeb #{Mix.Project.config[:version]}"

  @doc "Hostname to listen on."
  option [:host, :h], argname: "hostname"

  @doc "Port number to listen on."
  option [:port, :p] :: integer \\ 9000
end

defmodule MuWeb.CLI.DSL.Command.Inspect do
  @moduledoc """
  Log incoming requests to stdout, optionally sending a reply back.
  """

  @doc """
  Send the contents of file at PATH in response to incoming requests.

  By default, nothing is sent in response, the connection is closed immediately.

  Passing a dash (-) for <path> will read from stdin.
  """
  option [:reply_file, :f], path
end

defmodule MuWeb.CLI.DSL.Command.Proxy do
  @moduledoc """
  Work as a tunnelling proxy, logging all communications. All traffic
  between client and remote server is transmitted without alterations, but
  all requests and responses are logged to stdout.
  """

  @doc "URL to connect to."
  argument url
end

defmodule MuWeb.CLI.DSL.Command.Serve do
  @moduledoc """
  Serve files from the specified directory, recursively.
  """

  @action MuWeb.CLI.cmd_serve

  argument path \\ "."

  @doc """
  For directory requests, serve HTML with the list of files in that directory.

  Without this option, "403 Forbidden" is returned for directory requests.
  """
  option [:list, :l] :: boolean

end
