defmodule PgSiphon.ParserTest do
  use ExUnit.Case

  test "parse/1 with Parse message" do
    message_frame = <<80, 0, 0, 0, 28, 0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82, 79, 77, 32, 110, 97, 109, 101, 115, 59, 0, 0, 0, 68, 0, 0, 0, 6, 83, 0, 72, 0, 0, 0, 4>>
    assert [
      {80,
       <<0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82, 79,
         77, 32, 110, 97, 109, 101, 115, 59, 0, 0, 0>>},
      {68, <<83, 0>>},
      {72, ""}
    ] = PgSiphon.Parser.parse(message_frame)
  end
end
