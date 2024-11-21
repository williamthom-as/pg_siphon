# To subscribe:
#
# Example in GenServer:
#
# @impl true
# def init(:ok) do
#   Phoenix.PubSub.subscribe(:broadcaster, "message_frames")
#   {:ok, %State{}}
# end

# @impl true
# def handle_info({:new_message_frame, message}, state) do
#   IO.puts("RECEIVED: #{message}")
#   {:noreply, state}
# end
#
# Good reference: https://www.pompecki.com/post/phoenix-pubsub/

defmodule PgSiphon.Broadcaster do
  @pubsub_name :broadcaster
  @pubsub_topic "message_frames"

  def new_message_frame(messages) do
    Phoenix.PubSub.broadcast(@pubsub_name, @pubsub_topic, {:new_message_frame, messages})
  end

  def message_types_changed(message_types) do
    Phoenix.PubSub.broadcast(@pubsub_name, @pubsub_topic, {:message_types_changed, message_types})
  end

  def connections_changed() do
    Phoenix.PubSub.broadcast(@pubsub_name, @pubsub_topic, {:connections_changed})
  end
end
