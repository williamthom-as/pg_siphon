require Logger

defmodule PgSiphon.MonitoringServer do
  use GenServer

  @name :monitoring_server

  alias PgSiphon.Broadcaster

  import PgSiphon.Message, only: [log_message_frame: 1]

  defmodule State do
    defstruct recording: true, filter_message_types: [], count: 0
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

  def show_filter_types() do
    GenServer.cast(@name, :show_filter_types)
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
      new_filtered_types = [type | state.filter_message_types]

      Broadcaster.message_types_changed(new_filtered_types)

      {:noreply, %State{state | filter_message_types: new_filtered_types}}
    else
      Logger.error("Invalid message type: #{type}")
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:remove_filter_type, type}, state) do
    new_filtered_types = Enum.filter(state.filter_message_types, &(&1 != type))

    Broadcaster.message_types_changed(new_filtered_types)

    {:noreply, %State{state | filter_message_types: new_filtered_types}}
  end

  @impl true
  def handle_cast(:clear_filter_types, state) do
    Broadcaster.message_types_changed([])

    {:noreply, %State{state | filter_message_types: []}}
  end

  @impl true
  def handle_cast(:show_filter_types, state) do
    Logger.info("Filtering on FE message types: #{inspect(state.filter_message_types)}")

    {:noreply, state}
  end

  @impl true
  def handle_cast({:log_message, message}, state) do
    perform_log_message(message, state)

    {:noreply, %State{state | count: state.count + 1}}
  end

  defp perform_log_message(decoded_messages, %State{recording: true, filter_message_types: []}) do
    decoded_messages
    |> log_message_frame()

    :ok
  end

  defp perform_log_message(decoded_messages, %State{
         recording: true,
         filter_message_types: filter_message_types
       }) do
    decoded_messages
    |> Enum.filter(fn %PgSiphon.Message{type: type} ->
      Enum.member?(filter_message_types, type)
    end)
    |> log_message_frame()

    :ok
  end

  defp perform_log_message(_message, _state), do: :ok
end
