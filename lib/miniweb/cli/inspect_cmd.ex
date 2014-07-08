defmodule Miniweb.CLI.Inspect do
  defmodule Router do
    @moduledoc false
    use Muweb.Router
    import Miniweb.Handlers
    handle _, _, &inspect_handler, reply: param(:reply)
  end

  def run(port, reply_file) do
    reply = check_reply_option(reply_file)
    router = Router.init(reply: reply)
    Muweb.Server.start(router: router, port: port)
  end

  defp check_reply_option(reply_file) do
    case reply_file do
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
  end
end
