require Logger

defmodule PgSiphon.ProxyServer do
  use GenServer

  @name :proxy_server

  import PgSiphon.Message, only: [decode: 1]

  alias PgSiphon.QueryServer

  defmodule ProxyState do
    defstruct accept_pid: nil, from_port: 1337, to_host: 'localhost', to_port: 5432
  end

  # Client interface

  def start_link(_arg) do
    Logger.info "Starting ProxyServer..."

    result = GenServer.start_link(__MODULE__, %ProxyState{}, name: @name)

    case result do
      {:ok, s_pid} ->
        start_listen(s_pid)

        {:ok, s_pid}
      {:error, {:already_started, old_pid}} ->
        {:ok, old_pid}
      error ->
        Logger.error(inspect error)
    end
  end

  def stop do
    GenServer.stop(@name)
  end

  # GenServer callbacks

  def init(%ProxyState{} = state) do
    {:ok, state}
  end

  def handle_call(:listen, _from, state) do
    {:ok, l_sock} = :gen_tcp.listen(state.from_port, [
      :binary,
      packet: :raw,
      active: false
    ])

    Logger.info "Listening for connections on port #{state.from_port}"

    accept_pid = spawn_link(fn -> loop_accept(l_sock, state.to_host, state.to_port) end)

    {:reply, :ok, %{state | accept_pid: accept_pid}}
  end

  # Rely on supervisor to reboot
  def handle_info({:EXIT, _pid, reason}, %ProxyState{} = state) do
    IO.puts("Process exited with reason: #{inspect reason}")
    {:stop, {:exit, reason}, state}
  end

  defp start_listen(server_pid) do
    GenServer.call(server_pid, :listen)
  end

  defp loop_accept(l_sock, to_host, to_port) do
    Logger.debug "Waiting to accept connection..."

    {:ok, f_sock} = :gen_tcp.accept(l_sock)
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
        Logger.debug("Data recv:\n #{inspect(data, bin: :as_binaries, limit: :infinity)}")
        Logger.debug(decode(data))
        Logger.debug("--------")
        # Logger.debug(data)

        spawn(fn -> QueryServer.add_message(data) end)

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
