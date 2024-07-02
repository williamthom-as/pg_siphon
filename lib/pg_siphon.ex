defmodule PgSiphon do
  @moduledoc """
  Documentation for `PgSiphon`.
  """

  import Proxy

  def start_proxy() do
    start(5000, 'localhost', 5432)
  end

end
