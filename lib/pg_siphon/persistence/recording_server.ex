defmodule PgSiphon.Persistence.RecordingServer do
  use GenServer

  require Logger

  alias Phoenix.PubSub

  @name :recording_server
  @pubsub_topic "message_frames"

  defmodule State do
    defstruct recording: false, current_file: nil, file_name: nil, root_dir: nil
  end

  # Client API

  def start_link(_) do
    Logger.info("Starting recording server...")

    GenServer.start_link(__MODULE__, %State{}, name: @name)
  end

  def start(file_name) do
    GenServer.call(@name, {:start_export, file_name})
  end

  def stop() do
    GenServer.call(@name, :stop_export)
  end

  def recording?() do
    GenServer.call(@name, :recording?)
  end

  # Server callbacks

  def init(state) do
    root_dir =
      Application.get_env(:pg_siphon, :export)
      |> Keyword.get(:export_dir)

    {:ok, %{state | root_dir: root_dir}}
  end

  def handle_call({:start_export, file_name}, _from, %{recording: false} = state) do
    file_path = Path.join(state.root_dir, file_name <> ".raw.csv")

    Logger.info("Starting file export to #{file_path}")

    {:ok, file} = File.open(file_path, [:write])
    PubSub.subscribe(:broadcaster, @pubsub_topic)

    notify_external(:start, state.file_name)

    {:reply, {:ok, :started},
     %{state | recording: true, current_file: file, file_name: file_name}}
  end

  def handle_call({:start_export, _file_path}, _from, %{recording: true} = state) do
    {:reply, {:error, :already_started_export}, state}
  end

  def handle_call(:stop_export, _from, %{recording: true} = state) do
    Logger.info("Stopping file export")

    File.close(state.current_file)
    PubSub.unsubscribe(:broadcaster, @pubsub_topic)

    notify_external(:finish, state.file_name)

    {:reply, {:ok, :stopped}, %{state | recording: false, current_file: nil, file_name: nil}}
  end

  def handle_call(:stop_export, _from, %{recording: false} = state) do
    {:reply, {:error, :not_started}, state}
  end

  def handle_info({:new_message_frame, messages}, %{recording: true} = state)
      when is_list(messages) do
    messages
    |> Enum.each(fn %{type: type, payload: payload, time: time, extras: extras} ->
      escaped_payload = String.replace(payload, "\n", "")

      IO.puts "here freshed"
      IO.inspect extras

      extras_json =
        if is_map(extras) or is_list(extras) do
          Jason.encode!(extras)
        else
          ""
        end

      csv_row =
        [[type, escaped_payload, time, extras_json]]
        |> CSV.encode()
        |> Enum.join()

      IO.binwrite(state.current_file, csv_row)
    end)

    {:noreply, state}
  end

  def handle_info({:message_types_changed, _message_types}, state) do
    {:noreply, state}
  end

  def handle_info({:connections_changed}, state) do
    {:noreply, state}
  end

  def handle_info({@pubsub_topic, _message}, state) do
    {:noreply, state}
  end

  defp notify_external(status, file_name) do
    Phoenix.PubSub.broadcast(:recording_notifier, "recording", {
      status,
      %{file_name: file_name}
    })
  end
end
