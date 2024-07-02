require Logger

defmodule Proxy do

  import PgSiphon.Parser, only: [parse: 1]

  def start(from, to_host, to_port) do
    {:ok, ln_socket} = :gen_tcp.listen(from, [
      :binary,
      packet: :raw,
      active: false
    ])

    loop_accept(ln_socket, to_host, to_port)
  end

  defp loop_accept(ln_socket, to_host, to_port) do
    {:ok, from_socket} = :gen_tcp.accept(ln_socket)
    {:ok, to_socket} = :gen_tcp.connect(to_host, to_port, [
      :binary,
      packet: :raw,
      active: false
    ])

    spawn(fn -> loop_forward(from_socket, to_socket, :client) end)
    spawn(fn -> loop_forward(to_socket, from_socket, :server) end)

    loop_accept(ln_socket, to_host, to_port)
  end

  defp loop_forward(from_socket, to_socket, :client) do
    case :gen_tcp.recv(from_socket, 0) do
      {:ok, data} ->
        Logger.debug("Data recv:\n #{inspect(data, bin: :as_binary)}")
        Logger.debug(data)
        Logger.debug(parse(data))

        :gen_tcp.send(to_socket, data)
        loop_forward(from_socket, to_socket, :client)
      {:error, data} ->
        Logger.error("Error: #{inspect(data)}")

        :gen_tcp.close(from_socket)
        :gen_tcp.close(to_socket)
    end
  end

  defp loop_forward(from_socket, to_socket, :server) do
    case :gen_tcp.recv(from_socket, 0) do
      {:ok, data} ->
        :gen_tcp.send(to_socket, data)
        loop_forward(from_socket, to_socket, :server)
      {:error, _} ->
        :gen_tcp.close(from_socket)
        :gen_tcp.close(to_socket)
    end
  end
end
