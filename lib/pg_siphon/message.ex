require Logger

defmodule PgSiphon.Message do

  defstruct [:type, :length, :payload]

  # Postgres instructions
  # https://www.postgresql.org/docs/current/protocol-message-formats.html

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

  def decode(<<>>), do: []

  def decode(<<0, 0, 0, length::integer-size(8), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [{"0", message} | decode(rest)]
  end

  def decode(<<66, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [{"B", message} | decode(rest)]
  end

  def decode(<<67, length::integer-size(32), rest::binary>>) do
    length = length - 4
    <<desc_type::binary-size(1), message::binary-size(length - 1), rest::binary>> = rest

    [{"C", desc_type, message} | decode(rest)]
  end

  def decode(<<68, length::integer-size(32), rest::binary>>) do
    length = length - 4
    # desc_type -> 'S' to describe a prepared statement; or 'P' to describe a portal.
    <<desc_type::binary-size(1), message::binary-size(length - 1), rest::binary>> = rest

    [{"D", desc_type, message} | decode(rest)]
  end

  def decode(<<69, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [{"E", message} | decode(rest)]
  end

  def decode(<<72, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [{"H", message} | decode(rest)]
  end

  def decode(<<80, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [{"P", message} | decode(rest)]
  end

  def decode(<<81, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [{"Q", message} | decode(rest)]
  end

  def decode(<<83, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [{"S", message} | decode(rest)]
  end

  def decode(<<112, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [{"p", message} | decode(rest)]
  end

  def decode(unknown) when byte_size(unknown) >= 4 do
    Logger.debug("Unknown message cannot be parsed [#{unknown}]")
    []
  end

  def decode(_) do
    []
  end

  def valid_type?(type), do: Map.has_key?(@fe_msg_id, type)
end
