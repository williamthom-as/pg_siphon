require Logger

defmodule PgSiphon.QueryServer do
  use GenServer

  import PgSiphon.Message, only: [decode: 1]

  @name :query_server

  defmodule State do
    defstruct messages: [], filter_message_types: "P", recording: false
  end

  # Client interface

  def start_link(_arg) do
    Logger.info("Starting QueryServer...")

    GenServer.start_link(__MODULE__, %State{}, name: @name)
  end

  def clear_messages do
    GenServer.cast(@name, :clear)
  end

  def set_message_filter(filter) do
    GenServer.cast(@name, {:set_message_filter, filter})
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

  # Server callbacks

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_cast(:clear, state) do
    {:noreply, %State{state | messages: []}}
  end

  def handle_cast({:set_message_filter, filter}, state) do
    {:noreply, %State{state | filter_message_types: filter}}
  end

  def handle_cast({:set_recording, recording}, state) do
    {:noreply, %State{state | recording: recording}}
  end

  def handle_call({:add_message, message}, _from, state) do
    {:ok, new_state} = perform_message_insert(message, state)

    {:reply, :ok, new_state}
  end

  def handle_call(:get_messages, _from, state) do
    {:reply, state.messages, state}
  end

  # Implementation

  defp perform_message_insert(message, %State{messages: messages, recording: true} = state) do
    decoded_message = message
    |> decode()

    {:ok, %State{state | messages: messages ++ [decoded_message]}}
  end

  defp perform_message_insert(_, state) do
    {:ok, state}
  end

end
