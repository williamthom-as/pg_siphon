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

  def decode_messages(<<>>), do: []

  def decode_messages(<<80, length::binary-size(4), rest::binary>>) when byte_size(rest) >= 4 do
    length = :binary.decode_unsigned(length, :big) - 4
    <<message::binary-size(length), rest::binary>> = rest
    [{"P", message} | decode_messages(rest)]
  end

  def decode_messages(<<68, _::binary-size(4), rest::binary>>) do
    length = 0
    <<message::binary-size(length), rest::binary>> = rest

    [{"D", message} | decode_messages(rest)]
  end

  def decode_messages(<<72, _::binary-size(4), rest::binary>>) do
    length = 0
    <<message::binary-size(length), rest::binary>> = rest

    [{"H", message} | decode_messages(rest)]
  end

  def decode_messages(<<83, 0, rest::binary>>) do
    [{"S", ""} | decode_messages(rest)]
  end

  def decode_messages(<<_type::binary-size(1), length::binary-size(4), rest::binary>>) when byte_size(rest) >= 4 do
    length = :binary.decode_unsigned(length, :big)
    <<_::binary-size(length), rest::binary>> = rest
    decode_messages(rest)
  end

  def decode_messages(_) do
    []
  end

  def valid_type?(type), do: Map.has_key?(@fe_msg_id, type)
end
