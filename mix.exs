defmodule Miniweb.Mixfile do
  use Mix.Project

  def project do
    [app: :miniweb,
     version: "0.2.0",
     elixir: "~> 0.14.0",
     deps: deps,

     escript: [
       main_module: Miniweb.CLI,
       embed_elixir: true,
       name: :uweb,
     ],

     release: [
       main_module: Miniweb.CLI,
     ],
    ]
  end

  def application do
    [applications: [:muweb, :commando]]
  end

  defp deps do
    [{:muweb, github: "alco/muweb"},
     {:commando, github: "alco/commando"},
     {:exrm, github: "alco/exrm", ref: "cli", only: :rel}]
  end
end
