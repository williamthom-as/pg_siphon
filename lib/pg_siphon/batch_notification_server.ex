defmodule PgSiphon.BatchNotificationServer do
  use GenServer

  require Logger

  alias PgSiphon.Broadcaster

  @name :batch_notification_server

  defmodule State do
    defstruct messages: [],
              batch_size: 100,
              timeout_ms: 1000
  end

  # Client API

  def start_link(_args) do
    Logger.info("Starting Notification Server...")
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def send_message(message) do
    GenServer.call(@name, {:send_message, message})
  end

  def process_batch do
    GenServer.cast(@name, :process_batch)
  end

  def force_batch do
    GenServer.cast(@name, :force_batch)
  end

  # Server Callbacks

  def init(:ok) do
    state = %State{}

    :timer.send_interval(state.timeout_ms, self(), :force_batch)

    {:ok, state}
  end

  def handle_call({:send_message, message}, _from, state) do
    state = %State{state | messages: [message | state.messages]}
    process_batch()
    {:reply, :ok, state}
  end

  def handle_cast(:process_batch, %State{messages: messages} = state)
      when length(messages) >= state.batch_size do
    Logger.debug("Processing batch, #{length(messages)} messages")

    Broadcaster.new_message_frame(Enum.reverse(messages))
    {:noreply, %State{state | messages: []}}
  end

  def handle_cast(:process_batch, state) do
    Logger.debug("Processing batch, not enough messages")

    {:noreply, state}
  end

  def handle_cast(:force_batch, %State{messages: messages} = state) when length(messages) > 0 do
    Logger.debug("Forcing batch, #{length(messages)} messages")

    Broadcaster.new_message_frame(Enum.reverse(messages))
    {:noreply, %State{state | messages: []}}
  end

  def handle_cast(:force_batch, state) do
    Logger.debug("Forcing batch, no messages")

    {:noreply, state}
  end

  # Keep handle_info for timer-based force_batch
  def handle_info(:force_batch, state) do
    GenServer.cast(self(), :force_batch)
    {:noreply, state}
  end
end
