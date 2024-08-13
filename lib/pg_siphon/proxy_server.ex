require Logger

defmodule PgSiphon.ProxyServer do
  use GenServer

  @name :proxy_server

  alias PgSiphon.QueryServer
  alias PgSiphon.MonitoringServer

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

    spawn(fn -> loop_forward(f_sock, t_sock, :client, {0, nil}) end)
    spawn(fn -> loop_forward(t_sock, f_sock, :server) end)

    loop_accept(l_sock, to_host, to_port)
  end

  defp loop_forward(f_sock, t_sock, :client, {0, _}) do
    # recv all available bytes - 0
    case :gen_tcp.recv(f_sock, 0) do
      {:ok, data} ->
        # Logger.debug("Data recv:\n #{inspect(data, bin: :as_binaries, limit: :infinity)}")

        :gen_tcp.send(t_sock, data)

        # We need to handle more cases here
        <<msg_type::binary-size(1), length::integer-size(32), rest::binary>> = data
        buf = cond do
          msg_type == <<0>> ->
            {0, nil}
          (length - 4) > byte_size(rest) -> # Full message not received.
            {length, data}
          true ->
            <<packet::binary-size(length + 1), rest::binary>> = data

            # Logger.info("Splitting packet: #{inspect(packet, bin: :as_binaries, limit: :infinity)}")
            # Logger.info("Splitting rest: #{inspect(rest, bin: :as_binaries, limit: :infinity)}")

            process_message_frame(packet)
            {byte_size(rest), rest}
        end

        loop_forward(f_sock, t_sock, :client, buf)
      {:error, _} ->
        :gen_tcp.close(f_sock)
        :gen_tcp.close(t_sock)
    end
  end

  defp loop_forward(f_sock, t_sock, :client, {length, buf}) do
    case :gen_tcp.recv(f_sock, 0) do
      {:ok, data} ->
        # Logger.debug("Continued data recv:\n #{inspect(data, bin: :as_binaries, limit: :infinity)}")
        :gen_tcp.send(t_sock, data)

        buf = <<data::binary, buf::binary>>
        # Logger.info("Buffering data: #{inspect(buf, bin: :as_binaries, limit: :infinity)}")
        # Logger.info("Buffering data size: #{byte_size(buf)}, length: #{length}")

        if byte_size(buf) <= length do
          loop_forward(f_sock, t_sock, :client, {length, buf})
        else
          process_message_frame(buf)
          loop_forward(f_sock, t_sock, :client, {0, nil})
        end
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

  defp process_message_frame(data) do
    # Logger.debug("Processing data recv:\n #{inspect(data, bin: :as_binaries, limit: :infinity)}")

    spawn(fn -> QueryServer.add_message(data) end)
    spawn(fn -> MonitoringServer.log_message(data) end)
  end
end
