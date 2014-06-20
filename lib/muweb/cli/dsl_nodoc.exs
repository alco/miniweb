defmodule MuWeb.CLI.DSL do
  @prefix "mix"
  @name "muweb"
  @version "μWeb #{Mix.Project.config[:version]}"

  @options [
    host: [],
    port: [type: :integer, default: 9000],
  ]
end

defmodule MuWeb.CLI.DSL.Command.Inspect do
  option [:reply_file, :f], path
end

defmodule MuWeb.CLI.DSL.Command.Proxy do
  argument url
end

defmodule MuWeb.CLI.DSL.Command.Serve do
  option [:list, :l] :: boolean

  argument path \\ "."
end
