defmodule MicroWeb.Router.Mixin do
  defmacro param(name) when is_atom(name) do
    quote do: var!(_init_opts, nil)[unquote(name)]
  end


  defmacro params(list) when is_list(list) do
    #quote do: (@micro_web_router_params unquote(list))
  end


  defmacro mount(path, module, opts \\ [])

  defmacro mount(path, module, opts)
    when is_binary(path) and is_atom(module) and is_list(opts),
    do: do_mount(path, module, opts)

  defmacro mount(path, {:__aliases__, _, _}=module, opts)
    when is_binary(path) and is_list(opts),
    do: do_mount(path, module, opts)


  defp do_mount(path, module, _opts) do
    components = path_components(path)
    q = quote do
      def handle(method, [unquote_splicing(components) | rest], init_opts, conn) do
        unquote(module).handle(method, rest, init_opts, conn)
      end
    end
    #q |> Macro.to_string |> IO.puts
    q
  end


  defmacro handle(path, method, {:&, _, _}=func),
    do: do_handle(path, method, {:func, func}, [], __CALLER__.module)

  defmacro handle(path, method, [do: code]),
    do: do_handle(path, method, {:code, code}, [], __CALLER__.module)

  defmacro handle(path, method, {:wrap, _, args}),
    do: do_handle(path, method, {:wrap, args}, [], __CALLER__.module)

  defmacro handle(path, method, {:&, _, _}=func, opts)
    when is_list(opts),
    do: do_handle(path, method, {:func, func}, opts, __CALLER__.module)

  defmacro handle(path, method, opts, [do: code])
    when is_list(opts),
    do: do_handle(path, method, {:code, code}, opts, __CALLER__.module)

  defmacro handle(path, method, {:wrap, _, args}, opts),
    do: do_handle(path, method, {:wrap, args}, opts, __CALLER__.module)


  defp do_handle(path, method, handler, opts, caller) do
    methods = List.wrap(method)
    matchspec = path_to_matchspec(path, caller) |> quote_matchspec()

    quoted_body = quote_handler(handler, opts)

    quoted_head = if match?({:_, _, nil}, method) do
      quote do: handle(_, unquote(matchspec), var!(_init_opts, nil), var!(conn, nil))
    else
      quote do: handle(method, unquote(matchspec), var!(_init_opts, nil), var!(conn, nil)) when method in unquote(methods)
    end

    q = quote do
      def unquote(quoted_head) do
        unquote(quoted_body)
      end
    end
    #q |> Macro.to_string |> IO.puts
    q
  end


  defp path_components(path) do
    String.split(path, "/")
    |> MicroWeb.Util.strip_list()
  end


  defp path_to_matchspec(path, context) when is_binary(path) do
    components =
      path_components(path)
      |> Enum.map(fn
        ":" <> name -> {binary_to_atom(name), [], context}
        other       -> other
      end)

    reversed = Enum.reverse(components)
    if reversed != [] and hd(reversed) == "..." do
      {:glob, tl(reversed) |> Enum.reverse()}
    else
      components
    end
  end

  defp path_to_matchspec(path, _) when is_list(path) do
    path
  end

  defp path_to_matchspec({:_, _, nil}=path, _) do
    path
  end


  defp quote_matchspec(spec) do
    case spec do
      {:_, _, nil}  -> quote do: path
      {:glob, list} -> quote do: [unquote_splicing(list) | _]=path
      other         -> quote do: unquote(other)=path
    end
  end


  defp quote_handler(handler, opts) do
    case handler do
      {:func, {:&, meta, [arg]}} ->
        func = {:&, meta, [{:/, meta, [arg, 3]}]}
        quote do: unquote(func).(path, unquote(opts), var!(conn, nil))

      {:wrap, [{fun, _, _}, opts]} ->
        funcall = {fun, [], opts[:arguments]}
        quote do
          use MicroWeb.Handler
          val = unquote(funcall)
          reply(unquote(opts[:status] || 200), to_string(val))
        end

      {:code, code} ->
        quote do
          use MicroWeb.Handler
          unquote(code)
        end
    end
  end
end

defmodule MicroWeb.Router do
  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)
      import MicroWeb.Router.Mixin

      #Module.register_attribute(__MODULE__, :micro_web_router_params, accumulate: true)
    end
  end

  defmacro __before_compile__(_env) do
    #IO.inspect List.flatten(Module.get_attribute(env.module, :micro_web_router_params))
    quote do
      def init(opts) do
        {__MODULE__, opts}
      end
    end
  end
end
