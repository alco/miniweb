defmodule MicroWeb.Router do
  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)
      import unquote(__MODULE__), only: [handle: 3, handle: 4]
    end
  end

  defmacro handle(path, method, handler, opts \\ []) do
    qpath = case path_to_matchspec(path) do
      {:_, _, nil}  -> quote do: path
      {:glob, list} -> quote do: [unquote_splicing(list) | _]=path
      other         -> quote do: unquote(other)=path
    end
    methods = List.wrap(method)

    qbody = quote do
      unquote(handler).handle(path, unquote(opts), conn)
    end

    qhead = if match?({:_, _, nil}, method) do
      quote do: handle(_, unquote(qpath), conn)
    else
      quote do: (handle(method, unquote(qpath), conn) when method in unquote(methods))
    end

    q = quote do
      def unquote(qhead) do
        unquote(qbody)
      end
    end
    #q |> Macro.to_string |> IO.puts
    q
  end

  defp path_to_matchspec(path) when is_binary(path) do
    components =
      String.split(path, "/")
      |> MicroWeb.Util.strip_list()
      |> Enum.map(fn
        ":" <> name -> {binary_to_atom(name), [], nil}
        other       -> other
      end)

    reversed = Enum.reverse(components)
    if reversed != [] and hd(reversed) == "..." do
      {:glob, tl(reversed) |> Enum.reverse()}
    else
      components
    end
  end

  defp path_to_matchspec(path) when is_list(path) do
    path
  end

  defp path_to_matchspec({:_, _, nil}=path) do
    path
  end


  defmacro __before_compile__(_env) do
    #quote do
      #def handle(method, path, state) do
        #IO.puts "method = #{method}"
        #IO.puts "path = #{inspect path}"
        #IO.puts "state = #{inspect state}"
        #{:reply, "ok", state}
      #end
    #end
  end
end
