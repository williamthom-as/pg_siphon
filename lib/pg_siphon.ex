defmodule PgSiphon do
  @moduledoc false

  use Application

  def start(_type, _args) do
    IO.puts "Starting ..."
    children = [
      PgSiphon.ServicesSupervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PgSiphon.Supervisor)
  end

  def stop(_) do
    System.halt(0)
  end
end
