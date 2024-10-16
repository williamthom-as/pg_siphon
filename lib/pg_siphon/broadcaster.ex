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
# def handle_info({:notify, message}, state) do
#   IO.puts("RECEIVED: #{message}")
#   {:noreply, state}
# end
#
# Good reference: https://www.pompecki.com/post/phoenix-pubsub/

defmodule PgSiphon.Broadcaster do
  @pubsub_name :broadcaster
  @pubsub_topic "message_frames"

  def notify(messages) do
    Phoenix.PubSub.broadcast(@pubsub_name, @pubsub_topic, {:notify, messages})

    # This is to make the flow in log_message_frame work,
    # fix it. It's dumb to be this tightly coupled.
    messages.payload
  end
end
