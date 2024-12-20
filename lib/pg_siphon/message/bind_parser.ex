defmodule PgSiphon.Message.BindParser do
  # See more: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-BIND

  defstruct [
    # string
    :portal_name,
    # string
    :statement_name,
    # int16
    :param_fmt_count,
    # [int16]
    :param_fmts,
    # int16
    :param_count,
    # [{length(int32), value(binary)}]
    :param_vals,
    # int16
    :res_fmt_count,
    # [int16]
    :res_fmts
  ]

  def parse(bin) do
    {portal_name, rest} = get_str_val(bin)
    {statement_name, rest} = get_str_val(rest)
    <<param_fmt_count::integer-16, rest::binary>> = rest
    {param_fmts, rest} = get_int16_list(rest, param_fmt_count)
    <<param_count::integer-16, rest::binary>> = rest
    {param_vals, rest} = get_params(rest, param_count)
    <<res_fmt_count::integer-16, rest::binary>> = rest
    {res_fmts, _rest} = get_int16_list(rest, res_fmt_count)

    %__MODULE__{
      portal_name: portal_name,
      statement_name: statement_name,
      param_fmt_count: param_fmt_count,
      param_fmts: param_fmts,
      param_count: param_count,
      param_vals: param_vals,
      res_fmt_count: res_fmt_count,
      res_fmts: res_fmts
    }
  end

  defp get_str_val(bin) do
    get_null_term(bin)
  end

  defp get_null_term(bin), do: get_null_term(bin, [])
  defp get_null_term(<<0, rest::binary>>, acc), do: {to_string(Enum.reverse(acc)), rest}
  defp get_null_term(<<c, rest::binary>>, acc), do: get_null_term(rest, [c | acc])

  defp get_int16_list(bin, count), do: get_int16_list(bin, count, [])
  defp get_int16_list(bin, 0, acc), do: {Enum.reverse(acc), bin}

  defp get_int16_list(<<value::integer-16, rest::binary>>, count, acc) do
    get_int16_list(rest, count - 1, [value | acc])
  end

  defp get_params(bin, count), do: get_params(bin, count, [])
  defp get_params(bin, 0, acc), do: {Enum.reverse(acc), bin}

  defp get_params(
         <<length::integer-32, value::binary-size(length), rest::binary>>,
         count,
         acc
       ) do
    get_params(rest, count - 1, [{length, value} | acc])
  end
end
