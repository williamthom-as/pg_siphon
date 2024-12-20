require Logger

defmodule PgSiphon.Message do
  defstruct payload: "", type: "", length: 0, extras: %{}

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
    "0" => "Misc."
  }

  # There is a tonne of duplication in decode/1, payloads are different,
  # and I'm assumptively assuming in the future I'll want to do things different.

  def decode(<<>>), do: []

  # 80877103 = <<4, 210, 22, 47>>
  def decode(<<0, 0, 0, 8, 4, 210, 22, 47, rest::binary>>) do
    [
      %PgSiphon.Message{
        payload: <<4, 210, 22, 47>>,
        type: "0",
        length: 8
      }
      | decode(rest)
    ]
  end

  # tls handshake
  def decode(
        <<20, 3, 3, 0, 1, 1, 22, _major::8, _minor::8, length::16, _rest::binary>> = _message
      ) do
    [
      %PgSiphon.Message{
        payload: "Cannot process TLS messages",
        type: "0",
        length: length + 9
      }
    ]
  end

  # tls change cypher suite
  def decode(<<22, _major::8, _minor::8, length::16, _msg_type::8, _rest::binary>> = _message) do
    [
      %PgSiphon.Message{
        payload: "Cannot process TLS messages",
        type: "0",
        length: length + 5
      }
    ]
  end

  # tls message data
  def decode(<<23, length::integer-size(32), _rest::binary>> = _message) do
    [
      %PgSiphon.Message{
        payload: "Cannot process TLS messages",
        type: "0",
        length: length
      }
    ]
  end

  def decode(<<66, length::integer-size(32), rest::binary>>) when length - 4 <= byte_size(rest) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    extras =
      try do
        # We offload due to complexity.
        PgSiphon.Message.BindParser.parse(message)
        |> Map.from_struct()
      rescue
        e ->
          Logger.error("Failed to parse bind message: #{inspect(e)}")

          # Return empty map if we fail, who cares
          %{}
      end

    [
      %PgSiphon.Message{payload: message, type: "B", length: length, extras: extras}
      | decode(rest)
    ]
  end

  def decode(<<67, length::integer-size(32), rest::binary>>) when length - 4 <= byte_size(rest) do
    length = length - 4
    <<_desc_type::binary-size(1), message::binary-size(length - 1), rest::binary>> = rest

    # Ignoring desc type for now
    [%PgSiphon.Message{payload: message, type: "C", length: length} | decode(rest)]
  end

  # Possibly wrong?
  def decode(<<68, length::integer-size(32), rest::binary>>) when length - 4 <= byte_size(rest) do
    length = length - 4
    # desc_type -> 'S' to describe a prepared statement; or 'P' to describe a portal.
    <<_desc_type::binary-size(1), message::binary-size(length - 1), rest::binary>> = rest
    [%PgSiphon.Message{payload: message, type: "D", length: length} | decode(rest)]
  end

  def decode(<<69, length::integer-size(32), rest::binary>>) when length - 4 <= byte_size(rest) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [%PgSiphon.Message{payload: message, type: "E", length: length} | decode(rest)]
  end

  def decode(<<72, length::integer-size(32), rest::binary>>) when length - 4 <= byte_size(rest) do
    <<message::binary-size(length - 4), rest::binary>> = rest
    [%PgSiphon.Message{payload: message, type: "H", length: length} | decode(rest)]
  end

  def decode(<<80, length::integer-size(32), rest::binary>>) when length - 4 <= byte_size(rest) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    # split message on first null byte into prepared statement and content
    {prepared_statement, content} = bin_split(message)

    [
      %PgSiphon.Message{
        payload: content,
        type: "P",
        length: length,
        extras: %{
          prepared_statement: prepared_statement
        }
      }
      | decode(rest)
    ]
  end

  def decode(<<81, length::integer-size(32), rest::binary>>) when length - 4 <= byte_size(rest) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [%PgSiphon.Message{payload: message, type: "Q", length: length} | decode(rest)]
  end

  def decode(<<83, length::integer-size(32), rest::binary>>) when length - 4 <= byte_size(rest) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [%PgSiphon.Message{payload: message, type: "S", length: length} | decode(rest)]
  end

  def decode(<<88, length::integer-size(32), rest::binary>>) when length - 4 <= byte_size(rest) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [%PgSiphon.Message{payload: message, type: "X", length: length} | decode(rest)]
  end

  def decode(<<102, length::integer-size(32), rest::binary>>)
      when length - 4 <= byte_size(rest) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [%PgSiphon.Message{payload: message, type: "f", length: length} | decode(rest)]
  end

  def decode(<<112, length::integer-size(32), rest::binary>>)
      when length - 4 <= byte_size(rest) do
    <<message::binary-size(length - 4), rest::binary>> = rest

    [%PgSiphon.Message{payload: message, type: "p", length: length} | decode(rest)]
  end

  # We cannot assume we have the entire message. Partial non-messages are returned to caller
  # to be added in buffer
  def decode(excess) do
    Logger.debug(
      "Unparseable (likely excess): [#{inspect(excess, bin: :as_binary, limit: :infinity)}]"
    )

    [%PgSiphon.Message{payload: excess, type: "U", length: byte_size(excess)}]
  end

  def valid_type?(type), do: Map.has_key?(@fe_msg_id, type)

  def get_fe_message_types, do: @fe_msg_id

  def get_name_for_message_type(type) do
    Map.get(@fe_msg_id, type)
  end

  def log_message_frame(message_frame) do
    Enum.each(message_frame, fn %PgSiphon.Message{payload: payload, type: type, extras: extras} ->
      message =
        payload
        |> :binary.bin_to_list()
        |> Enum.reject(&(&1 == 0))
        |> List.to_string()

      notification = %{
        payload: message,
        type: type,
        extras: extras,
        time: :os.system_time(:millisecond)
      }

      PgSiphon.BatchNotificationServer.send_message(notification)
      Logger.debug("Type: #{type} Message: #{message}")
    end)
  end

  def bin_split(binary, split_on \\ <<0>>) do
    case :binary.match(binary, split_on) do
      {index, 1} ->
        <<first::binary-size(index), 0, rest::binary>> = binary

        {first, rest}

      :nomatch ->
        {binary, <<>>}
    end
  end
end
