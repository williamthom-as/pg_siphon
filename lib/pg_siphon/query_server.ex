require Logger

defmodule PgSiphon.QueryServer do
  use GenServer

  alias PgSiphon.Message

  import PgSiphon.Message, only: [decode: 1]

  @name :query_server

  defmodule State do
    defstruct table: nil, recording: false
  end

  # Client interface

  def start_link(_args) do
    Logger.info("Starting QueryServer...")

    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def clear_messages do
    GenServer.cast(@name, :clear)
  end

  def set_recording(recording) do
    GenServer.cast(@name, {:set_recording, recording})
  end

  def add_message(message) do
    GenServer.call(@name, {:add_message, message})
  end

  def get_messages() do
    GenServer.call(@name, :get_messages)
  end

  def get_message_count() do
    GenServer.call(@name, :get_message_count)
  end

  # Server callbacks

  @impl true
  def init(:ok) do
    table = :ets.new(:query_table, [:named_table, :public, :set, {:keypos, 1}])

    {:ok, %State{table: table}}
  end

  @impl true
  def handle_cast(:clear, state) do
    :ets.delete_all_objects(state.table)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:set_recording, recording}, state) do
    {:noreply, %State{state | recording: recording}}
  end

  @impl true
  def handle_call({:add_message, message}, _from, state) do
    {:ok, new_state} = perform_message_insert(message, state)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_messages, _from, state) do
    messages = :ets.tab2list(state.table)
    {:reply, messages, state}
  end

  @impl true
  def handle_call(:get_message_count, _from, state) do
    count = :ets.info(state.table, :size)
    {:reply, count, state}
  end

  # Implementation

  defp perform_message_insert(decoded_messages, %State{table: table, recording: true} = state) do
    # decoded_messages = message
    # |> decode()

    Enum.each(decoded_messages, fn %Message{payload: payload, type: type, length: length} ->
      case :ets.lookup(table, payload) do
        [] ->
          :ets.insert(state.table, {payload, type, length, 1})
        [{payload, type, length, count}] ->
          :ets.insert(state.table, {payload, type, length, count + 1})
      end
    end)

    {:ok, state}
  end

  defp perform_message_insert(_, state) do
    {:ok, state}
  end
end
