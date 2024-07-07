require Logger

defmodule PgSiphon.QueryServer do
  use GenServer

  @name :query_server

  defmodule State do
    defstruct queries: []
  end

  def start_link(_arg) do

  end


end
