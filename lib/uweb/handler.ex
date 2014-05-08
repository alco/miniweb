defmodule MicroWeb.Handler do
  @proto_version "1.1"

  defmacro __using__(_) do
    quote do
      import Kernel, except: [def: 2]
      import unquote(__MODULE__), only: :macros
    end
  end


  defmacro reply(status, opts \\ []) do
    quote do
      unquote(__MODULE__).reply(unquote(status), unquote(opts), var!(conn, __MODULE__))
    end
  end

  defmacro reply_file(status, path, opts \\ []) do
    quote do
      unquote(__MODULE__).reply_file(unquote(status), unquote(path), unquote(opts), var!(conn, __MODULE__))
    end
  end

  def reply(status, opts, conn) do
    headers = opts[:headers] || %{}
    data = opts[:data]
    if data and !Map.get(headers, "content-length") do
      headers = Map.put(headers, "content-length", byte_size(data))
    end
    reply_http(conn, status, headers, data)
  end

  def reply_file(status, path, opts, conn) do
    headers = opts[:headers] || %{}
    {status, data} = case File.read(path) do
      {:error, :enoent} ->
        {404, nil}
      {:ok, data} ->
        if !Map.get(headers, "content-length") do
          headers = Map.put(headers, "content-length", byte_size(data))
        end
        {status, data}
    end
    reply_http(conn, status, headers, data)
  end


  defmacro def({:handle, _, args}, [do: code]) do
    quote do
      def handle(unquote_splicing(args), var!(conn, __MODULE__)) do
        unquote(code)
      end
    end
  end


  defp reply_http(conn, status, headers, data) do
    import Kernel, except: [send: 2]
    import MicroWeb.Server, only: [send: 2]

    status_string = "HTTP/#{@proto_version} #{status} #{symbolic_status(status)}"

    send(conn, status_string <> "\r\n")
    Enum.each(headers, fn {name, value} ->
      send(conn, "#{name}: #{value}\r\n")
    end)
    send(conn, "\r\n")
    if data, do: send(conn, data)
    {:noreply, nil}
  end

  defp symbolic_status(status) do
    case status do
      # 1xx Informational
      100 -> "Continue"
      101 -> "Switching Protocols"
      #102 -> "Processing"                       # WebDAV; RFC 2518

      # 2xx Success
      200 -> "OK"
      201 -> "Created"
      202 -> "Accepted"
      203 -> "Non-Authoritative Information"    # since HTTP/1.1
      204 -> "No Content"
      205 -> "Reset Content"
      206 -> "Partial Content"
      #207 -> "Multi-Status"                     # WebDAV; RFC 4918
      #208 -> "Already Reported"                 # WebDAV; RFC 5842
      226 -> "IM Used"                          # RFC 3229

      # 3xx Redirection
      300 -> "Multiple Choices"
      301 -> "Moved Permanently"
      302 -> "Found"
      303 -> "See Other"                        # since HTTP/1.1
      304 -> "Not Modified"
      305 -> "Use Proxy"                        # since HTTP/1.1
      306 -> "Switch Proxy"
      307 -> "Temporary Redirect"               # since HTTP/1.1
      308 -> "Permanent Redirect"               # approved as experimental RFC

      # 4xx Client Error
      400 -> "Bad request"
      401 -> "Unauthorized"
      402 -> "Payment Required"
      403 -> "Forbidden"
      404 -> "Not Found"
      405 -> "Method Not Allowed"
      406 -> "Not Acceptable"
      #407 -> "Proxy Authentication Required"
      #408 -> "Request Timeout"
      #409 -> "Conflict"
      #410 -> "Gone"
      #411 -> "Length Required"
      #412 -> "Precondition Failed"
      #413 -> "Request Entity Too Large"
      #414 -> "Request-URI Too Long"
      #415 -> "Unsupported Media Type"
      #416 -> "Requested Range Not Satisfiable"
      #417 -> "Expectation Failed"
      #418 -> "I'm a teapot"                     # RFC 2324
      #419 -> "Authentication Timeout"           # not in RFC 2616
      #422 -> "Unprocessable Entity"             # WebDAV; RFC 4918
      #423 -> "Locked"                           # WebDAV; RFC 4918
      #424 -> "Failed Dependency"                # WebDAV; RFC 4918
      #426 -> "Upgrade Required"                 # RFC 2817
      #428 -> "Precondition Required"            # RFC 6585
      #429 -> "Too Many Requests"                # RFC 6585
      #431 -> "Request Header Fields Too Large"  # RFC 6585

      # 5xx Server Error
      500 -> "Internal Server Error"
      501 -> "Not Implemented"
      #502 -> "Bad Gateway"
      503 -> "Service Unavailable"
      #504 -> "Gateway Timeout"
      505 -> "HTTP Version Not Supported"
      #506 -> "Variant Also Negotiates"          # RFC 2295
      #507 -> "Insufficient Storage"             # WebDAV; RFC 4918
      #508 -> "Loop Detected"                    # WebDAV; RFC 5842
      #510 -> "Not Extended"                     # RFC 2774
      #511 -> "Network Authentication Required"  # RFC 6585
    end
  end
end
