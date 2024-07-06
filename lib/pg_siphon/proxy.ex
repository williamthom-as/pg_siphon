require Logger

defmodule PgSiphon.Proxy do

  import PgSiphon.Parser, only: [parse: 1]

  def start(from_port, to_host, to_port) do
    {:ok, l_sock} = :gen_tcp.listen(from_port, [
      :binary,
      packet: :raw,
      active: false
    ])

    Logger.info "Listening for connections on port #{from_port}"

    loop_accept(l_sock, to_host, to_port)
  end

  defp loop_accept(l_sock, to_host, to_port) do

    Logger.debug "Waiting to accept connection..."

    {:ok, f_sock} = :gen_tcp.accept(l_sock)

    Logger.debug "#{to_host}:#{to_port}"

    {:ok, t_sock} = :gen_tcp.connect(to_host, to_port, [
      :binary,
      packet: :raw,
      active: false
    ])

    Logger.debug "Connection accepted!"

    spawn(fn -> loop_forward(f_sock, t_sock, :client) end)
    spawn(fn -> loop_forward(t_sock, f_sock, :server) end)

    loop_accept(l_sock, to_host, to_port)
  end

  defp loop_forward(f_sock, t_sock, :client) do
    # recv all available bytes - 0
    case :gen_tcp.recv(f_sock, 0) do
      {:ok, data} ->
        # Logger.debug("Data recv:\n #{inspect(data, bin: :as_binary)}")
        # Logger.debug(data)
        Logger.debug(parse(data))

        :gen_tcp.send(t_sock, data)
        loop_forward(f_sock, t_sock, :client)
      {:error, _} ->
        :gen_tcp.close(f_sock)
        :gen_tcp.close(t_sock)
    end
  end

  defp loop_forward(f_sock, t_sock, :server) do
    case :gen_tcp.recv(f_sock, 0) do
      {:ok, data} ->
        :gen_tcp.send(t_sock, data)
        loop_forward(f_sock, t_sock, :server)
      {:error, _} ->
        :gen_tcp.close(f_sock)
        :gen_tcp.close(t_sock)
    end
  end
end