require Logger

defmodule PgSiphon.Loader do
  use GenServer

  def start_link(_arg) do
    Logger.info "Starting proxy loader process ... "
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Process.flag(:trap_exit, true)
    s_pid = start_server()

    {:ok, s_pid}
  end

  def handle_info({:EXIT, _pid, reason}, _state) do
    case reason do
      {:error, {:already_started, old_pid}} ->
        {:noreply, old_pid}
      error ->
        Logger.error("Proxy server exited (#{inspect error})")
        s_pid = start_server()

        {:noreply, s_pid}
    end
  end

  defp start_server do
    Logger.info "(Re)Starting Proxy server ..."
    s_pid = spawn_link(PgSiphon.Proxy, :start, [5000, 'localhost', 5432])
    send s_pid,

    Process.register(s_pid, :proxy_server)

    s_pid
  end
end
