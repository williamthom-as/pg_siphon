defmodule PgSiphon.Persistence.RecordingServerTest do
  use ExUnit.Case, async: true

  alias PgSiphon.Persistence.RecordingServer
  alias Phoenix.PubSub

  @pubsub_name :broadcaster
  @pubsub_topic "message_frames"

  @file_path "test.log"

  test "writes messages to the file" do
    assert {:ok, :started} = RecordingServer.start(@file_path)
    # check cant start twice
    {:error, :already_started_export} = RecordingServer.start(@file_path)

    # send msg
    PubSub.broadcast(
      @pubsub_name,
      @pubsub_topic,
      {:new_message_frame, [%{type: "a", payload: "a", time: "1234"}]}
    )

    PubSub.broadcast(
      @pubsub_name,
      @pubsub_topic,
      {:new_message_frame, [%{type: "b", payload: "b", time: "5678"}]}
    )

    # wait for a bit
    :timer.sleep(100)

    assert {:ok, :stopped} == RecordingServer.stop()
    assert {:error, :not_started} == RecordingServer.stop()

    {:ok, content} = File.read("test.log" <> ".raw.csv")
    assert content =~ "a,a,1234\r\nb,b,5678\r\n"

    File.rm(@file_path)
  end
end
