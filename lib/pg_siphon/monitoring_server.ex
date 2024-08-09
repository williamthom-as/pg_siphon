require Logger

defmodule PgSiphon.MonitoringServer do
  use GenServer

  alias PgSiphon.QueryServer

  @name :monitoring_server

  defmodule State do
    defstruct recording: false, filter_message_types: [], count: 0
  end

  def start_link(_args) do
    Logger.info("Starting Monitoring Server...")

    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def set_recording(recording) do
    GenServer.cast(@name, {:set_recording, recording})
  end

  def add_filter_type(type) do
    GenServer.cast(@name, {:add_filter_type, type})
  end

  def remove_filter_type(type) do
    GenServer.cast(@name, {:remove_filter_type, type})
  end

  def clear_filter_types() do
    GenServer.cast(@name, :clear_filter_types)
  end

  def log_message(message) do
    GenServer.cast(@name, {:log_message, message})
  end

  @impl true
  def init(:ok) do
    {:ok, %State{}}
  end

  @impl true
  def handle_cast({:set_recording, recording}, state) do
    {:noreply, %State{state | recording: recording}}
  end

  @impl true
  def handle_cast({:add_filter_type, type}, state) do
    if PgSiphon.Message.valid_type?(type) && !Enum.member?(state.filter_message_types, type) do
      {:noreply, %State{state | filter_message_types: [type | state.filter_message_types]}}
    else
      Logger.error("Invalid message type: #{type}")
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:remove_filter_type, type}, state) do
    {:noreply, %State{state | filter_message_types:
      Enum.filter(state.filter_message_types, &(&1 != type))}
    }
  end

  @impl true
  def handle_cast(:clear_filter_types, state) do
    {:noreply, %State{state | filter_message_types: []}}
  end

  @impl true
  def handle_cast({:log_message, message}, state) do
    perform_log_message(message, state)

    {:noreply, state}
  end

  defp perform_log_message(message, %State{recording: true, filter_message_types: filter_message_types}) do
    message
    |> PgSiphon.Message.decode() # No need to do this twice.
    |> Enum.each(fn %PgSiphon.Message{payload: payload, type: type, length: _length} ->
      if Enum.member?(filter_message_types, type) do
        payload
        |> :binary.bin_to_list()
        |> List.to_string()
        |> (&("Type: " <> type <> " Message: " <> &1)).()
        |> Logger.debug()
      end
    end)
  end

  defp perform_log_message(_message, _state), do: :ok
end
