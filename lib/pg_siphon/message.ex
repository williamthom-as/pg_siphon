defmodule PgSiphon.Message do

  defstruct [:type, :length, :payload]

  @fe_msg_id %{
    "p" => "Authentication message",
    "Q" => "Simple query",
    "P" => "Parse",
    "B" => "Bind",
    "E" => "Execute",
    "D" => "Describe",
    "C" => "Close",
    "H" => "Flush",
    "S" => "Sync",
    "F" => "Function call",
    "d" => "Copy data",
    "c" => "Copy completion",
    "f" => "Copy failure",
    "X" => "Termination",
    "0" => nil
  }

  def decode(<<type::binary-size(1), length::integer-size(32), payload::binary>>) do
    %PgSiphon.Message{type: type, length: length, payload: payload}
  end

  def valid_type?(type), do: Map.has_key?(@fe_msg_id, type)
end
