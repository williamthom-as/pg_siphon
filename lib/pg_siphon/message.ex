require Logger

defmodule PgSiphon.Message do

  defstruct [:payload, :type, :length]

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

  # There is a tonne of duplication in decode/1, payloads are different,
  # and I'm assumptively assuming in the future I'll want to do things different.

  def decode(<<>>), do: []

  def decode(<<0, 0, 0, length::integer-size(8), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest
    [%PgSiphon.Message{payload: message, type: "0", length: length} | decode(rest)]
  end

  def decode(<<66, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest
    [%PgSiphon.Message{payload: message, type: "B", length: length} | decode(rest)]
  end

  def decode(<<67, length::integer-size(32), rest::binary>>) do
    length = length - 4
    <<_desc_type::binary-size(1), message::binary-size(length - 1), rest::binary>> = rest

    # Ignoring desc type for now
    [%PgSiphon.Message{payload: message, type: "C", length: length} | decode(rest)]
  end

  def decode(<<68, length::integer-size(32), rest::binary>>) do
    length = length - 4
    # desc_type -> 'S' to describe a prepared statement; or 'P' to describe a portal.
    <<_desc_type::binary-size(1), message::binary-size(length - 1), rest::binary>> = rest

    # Ignoring desc type for now
    [%PgSiphon.Message{payload: message, type: "D", length: length} | decode(rest)]
  end

  def decode(<<69, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [%PgSiphon.Message{payload: message, type: "E", length: length} | decode(rest)]
  end

  def decode(<<72, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [%PgSiphon.Message{payload: message, type: "H", length: length} | decode(rest)]
  end

  def decode(<<80, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [%PgSiphon.Message{payload: message, type: "P", length: length} | decode(rest)]
  end

  def decode(<<81, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [%PgSiphon.Message{payload: message, type: "Q", length: length} | decode(rest)]
  end

  def decode(<<83, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [%PgSiphon.Message{payload: message, type: "S", length: length} | decode(rest)]
  end

  def decode(<<88, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [%PgSiphon.Message{payload: message, type: "X", length: length} | decode(rest)]
  end

  def decode(<<112, length::integer-size(32), rest::binary>>) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [%PgSiphon.Message{payload: message, type: "p", length: length} | decode(rest)]
  end

  def decode(unknown) when byte_size(unknown) >= 4 do
    Logger.debug(
      "Unknown message cannot be parsed [#{inspect(unknown, bin: :as_binary, limit: :infinity)}]"
    )

    []
  end

  def decode(_) do
    []
  end

  def valid_type?(type), do: Map.has_key?(@fe_msg_id, type)

  def get_fe_message_types, do: @fe_msg_id

  def log_message_frame(message_frame) do
    message_frame
    |> Enum.each(fn %PgSiphon.Message{payload: payload, type: type, length: _length} ->
      # Logger.debug(inspect(payload, bin: :as_binaries, limit: :infinity))

      payload
      |> :binary.bin_to_list()
      |> Enum.filter(&(&1 != 0)) # Strip out null bytes
      |> List.to_string()
      |> (&("Type: " <> type <> " Message: " <> &1)).()
      |> Logger.debug()
    end)
  end
end
