require Logger

defmodule PgSiphon.ProxyServer do
  use GenServer

  @name :proxy_server

  alias PgSiphon.QueryServer
  alias PgSiphon.MonitoringServer

  defmodule ProxyState do
    defstruct accept_pid: nil, from_port: 1337, to_host: 'localhost', to_port: 5432, running: false
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

  def running_state do
    GenServer.call(@name, :running_state)
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

    {:reply, :ok, %{state | accept_pid: accept_pid, running: true}}
  end

  def handle_cast(:running_state, _from, state) do
    {:reply, state.running, state}
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

    # Should record this against query later for IDS.
    {:ok, {ip, port}} = :inet.peername(f_sock)
    Logger.debug "Connection accepted from #{inspect(ip)}:#{port}"

    spawn(fn -> loop_forward(f_sock, t_sock, :client, {0, nil}) end)
    spawn(fn -> loop_forward(t_sock, f_sock, :server) end)

    loop_accept(l_sock, to_host, to_port)
  end

  # New frame
  defp loop_forward(f_sock, t_sock, :client, {0, _data}) do
    case :gen_tcp.recv(f_sock, 0) do
      {:ok, data} ->
        # Logger.debug("Data recv:\n #{inspect(data, bin: :as_binaries, limit: :infinity)}")

        :gen_tcp.send(t_sock, data)

        <<msg_type::binary-size(1), _length::integer-size(32), _rest::binary>> = data
        buf = cond do
          msg_type == <<0>> ->
            {0, nil}
          msg_type == <<1>> ->
            {0, nil}
          true ->
            {buffered, messages} =
              PgSiphon.Message.decode(data)
              |> Enum.split_with(fn message -> message.type == "U" end)

            dispatch_full_frames(messages)
            calculate_buf(buffered)
        end

        loop_forward(f_sock, t_sock, :client, buf)
      {:error, _} ->
        :gen_tcp.close(f_sock)
        :gen_tcp.close(t_sock)
    end
  end

  # Continuation frame
  defp loop_forward(f_sock, t_sock, :client, {_length, buf}) do
    case :gen_tcp.recv(f_sock, 0) do
      {:ok, data} ->
        :gen_tcp.send(t_sock, data)

        joined_data = <<buf::binary, data::binary>>
        Logger.debug("Continued data recv:\n #{inspect(joined_data, bin: :as_binaries, limit: :infinity)}")

        {buffered, messages} =
          PgSiphon.Message.decode(joined_data)
          |> Enum.split_with(fn message -> message.type == "U" end)

        dispatch_full_frames(messages)
        buf = calculate_buf(buffered)

        loop_forward(f_sock, t_sock, :client, buf)
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

  defp calculate_buf(buffered) do
    if (length(buffered) > 0) do
      buf = buffered |> Enum.map(fn message -> message.payload end) |> Enum.join()

      {byte_size(buf), buf}
    else
      {0, nil}
    end
  end

  defp dispatch_full_frames(decoded_messages) do
    spawn(fn -> QueryServer.add_message(decoded_messages) end)
    spawn(fn -> MonitoringServer.log_message(decoded_messages) end)
  end
end
