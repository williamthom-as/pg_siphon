defmodule PgSiphon.ActiveConnectionsServer do
  use GenServer

  require Logger

  @name :active_connection_server

  defmodule State do
    defstruct table: nil
  end

  # Client interface

  def start_link(_args) do
    Logger.info("Starting ActiveConnectionServer...")

    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def add_connection({_ip, _port} = connection, timestamp) do
    GenServer.call(
      @name,
      {:add_connection,
       %{
         connection: connection,
         timestamp: timestamp
       }}
    )
  end

  def get_active_connections() do
    GenServer.call(@name, :get_active_connections)
  end

  def clear_idle_connections() do
    GenServer.cast(@name, :clear_expired_connections)
  end

  # Server callbacks

  @impl true
  def init(:ok) do
    table = :ets.new(:active_connections, [:named_table, :public, :set, {:keypos, 1}])

    {:ok, %State{table: table}}
  end

  @impl true
  def handle_cast(:clear_expired_connections, state) do
    current_time = :os.system_time(:seconds)
    five_minutes_ago = current_time - 300

    :ets.select_delete(state.table, [
      {
        {:"$1", :"$2"},
        [{:<, :"$2", five_minutes_ago}],
        [true]
      }
    ])

    {:noreply, state}
  end

  @impl true
  def handle_call({:add_connection, connection}, _from, state) do
    {:ok, new_state} = perform_insert(connection, state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_active_connections, _from, state) do
    messages = :ets.tab2list(state.table)
    {:reply, messages, state}
  end

  # Implementation

  defp perform_insert(%{connection: conn, timestamp: ts}, %State{table: table}) do
    # upsert connection with the new ts.
    :ets.insert(table, {conn, ts})

    # fire call to clear out any expired connections.
    send(self(), :clear_idle_connections)

    {:ok, %State{table: table}}
  end
end
