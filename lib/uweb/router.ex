defmodule MicroWeb.Router do
  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)
      import unquote(__MODULE__), only: [handle: 3, handle: 4]
    end
  end

  defmacro handle(path, method, handler, opts \\ []) do
    IO.inspect path
    IO.inspect method
    IO.inspect handler
    IO.inspect opts
    nil
  end

  defmacro __before_compile__(_env) do
    quote do
      def handle(method, path, state) do
        IO.puts "method = #{method}"
        IO.puts "path = #{inspect path}"
        IO.puts "state = #{inspect state}"
        {:reply, "ok", state}
      end
    end
  end
end
