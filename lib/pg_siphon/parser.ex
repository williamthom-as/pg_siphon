defmodule PgSiphon.Parser do

  def parse(binary), do: parse(binary, [])

  defp parse(<<>>, messages), do: Enum.reverse(messages)

  defp parse(<<0, _rest::binary>>, messages), do: Enum.reverse(messages)

  defp parse(<<type::8, length::32-big, payload::binary-size(length - 4), rest::binary>>, messages) do
    message = {type, payload}

    parse(rest, [message | messages])
  end
end
