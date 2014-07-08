defmodule Miniweb.Mixfile do
  use Mix.Project

  def project do
    [app: :miniweb,
     version: "0.1.0",
     elixir: "~> 0.14.0",
     deps: deps,

     escript: [
       main_module: Miniweb.CLI,
       name: :uweb,
     ],
    ]
  end

  def application do
    []
  end

  defp deps do
    [{:muweb, path: Path.expand("../muweb", __DIR__)},
     {:commando, github: "alco/commando"}]
  end
end
