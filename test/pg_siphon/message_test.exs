defmodule PgSiphon.MessageTest do
  use ExUnit.Case

  test "parse/1 with P -> DSH messages" do
    message_frame = <<80, 0, 0, 0, 28, 0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82, 79, 77, 32, 110, 97, 109, 101, 115, 59, 0, 0, 0, 68, 0, 0, 0, 6, 83, 0, 72, 0, 0, 0, 4>>
    assert [
      {"P",
       <<0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82, 79,
         77, 32, 110, 97, 109, 101, 115, 59, 0, 0, 0>>},
      {"D", "S", <<0>>},
      {"H", ""}
    ] = PgSiphon.Message.decode(message_frame)
  end

  test "parse/1 with B,E,C,S messages" do
    message_frame = <<66, 0, 0, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 69, 0, 0, 0, 9, 0, 0, 0, 0, 0, 67, 0, 0, 0, 6, 83, 0, 83, 0, 0, 0, 4>>
    assert [
      {"B", <<0, 0, 0, 0, 0, 0, 0, 1, 0, 1>>},
      {"E", <<0, 0, 0, 0, 0>>},
      {"C", "S", <<0>>},
      {"S", ""}
    ] = PgSiphon.Message.decode(message_frame)
  end

  test "parse/1 with starting connection messages" do
    message_frame = <<0, 0, 0, 40, 0, 3, 0, 0, 117, 115, 101, 114, 0, 112, 111, 115, 116, 103, 114, 101, 115, 0, 100, 97, 116, 97, 98, 97, 115, 101, 0, 116, 101, 115, 116, 95, 100, 98, 0, 0>>
    assert [
      {"0",
       <<0, 3, 0, 0, 117, 115, 101, 114, 0, 112, 111, 115,
         116, 103, 114, 101, 115, 0, 100, 97, 116, 97, 98,
         97, 115, 101, 0, 116, 101, 115, 116, 95, 100, 98,
         0, 0>>}
    ] = PgSiphon.Message.decode(message_frame)
  end

  test "parse/1 with sync message" do
    message_frame = <<83, 0, 0, 0, 4>>
    assert [{"S", ""}] = PgSiphon.Message.decode(message_frame)
  end
end
