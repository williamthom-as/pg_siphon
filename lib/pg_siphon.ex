defmodule PgSiphon do
  @moduledoc false

  require Logger

  use Application

  def start(_type, _args) do
    Logger.info("Starting application supervision tree ...")

    children = [
      {Phoenix.PubSub, name: :broadcaster},
      PgSiphon.ServicesSupervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PgSiphon.Supervisor)
  end

  def stop(_) do
    System.halt(0)
    :ok
  end
end
