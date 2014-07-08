use Mix.Config

cfg = Path.expand("#{Mix.env}.exs", __DIR__)
if File.exists?(cfg) do
  import_config cfg
end
