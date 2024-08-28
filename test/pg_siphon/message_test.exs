defmodule PgSiphon.MessageTest do
  use ExUnit.Case

  test "parse/1 with P -> DSH messages" do
    message_frame = <<80, 0, 0, 0, 28, 0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82, 79, 77, 32, 110, 97, 109, 101, 115, 59, 0, 0, 0, 68, 0, 0, 0, 6, 83, 0, 72, 0, 0, 0, 4>>
    assert [
      %PgSiphon.Message{
        payload: <<0, 83, 69, 76, 69, 67, 84, 32, 42, 32,
          70, 82, 79, 77, 32, 110, 97, 109, 101, 115, 59, 0,
          0, 0>>,
        type: "P",
        length: 28
      },
      %PgSiphon.Message{
        payload: <<0>>,
        type: "D",
        length: 2
      },
      %PgSiphon.Message{payload: "", type: "H", length: 4}
    ] = PgSiphon.Message.decode(message_frame)
  end

  test "parse/1 with B,E,C,S messages" do
    message_frame = <<66, 0, 0, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 69, 0, 0, 0, 9, 0, 0, 0, 0, 0, 67, 0, 0, 0, 6, 83, 0, 83, 0, 0, 0, 4>>
    assert [
      %PgSiphon.Message{
        payload: <<0, 0, 0, 0, 0, 0, 0, 1, 0, 1>>,
        type: "B",
        length: 14
      },
      %PgSiphon.Message{
        payload: <<0, 0, 0, 0, 0>>,
        type: "E",
        length: 9
      },
      %PgSiphon.Message{
        payload: <<0>>,
        type: "C",
        length: 2
      },
      %PgSiphon.Message{payload: "", type: "S", length: 4}
    ] = PgSiphon.Message.decode(message_frame)
  end

  test "parse/1 with starting connection messages" do
    message_frame = <<0, 0, 0, 40, 0, 3, 0, 0, 117, 115, 101, 114, 0, 112, 111, 115, 116, 103, 114, 101, 115, 0, 100, 97, 116, 97, 98, 97, 115, 101, 0, 116, 101, 115, 116, 95, 100, 98, 0, 0>>
    assert [
      %PgSiphon.Message{
        payload: <<0, 3, 0, 0, 117, 115, 101, 114, 0, 112,
          111, 115, 116, 103, 114, 101, 115, 0, 100, 97,
          116, 97, 98, 97, 115, 101, 0, 116, 101, 115, 116,
          95, 100, 98, 0, 0>>,
        type: "0",
        length: 40
      }
    ] = PgSiphon.Message.decode(message_frame)
  end

  test "parse/1 with sync message" do
    message_frame = <<83, 0, 0, 0, 4>>
    assert [%PgSiphon.Message{payload: "", type: "S", length: 4}] = PgSiphon.Message.decode(message_frame)
  end

  test "decode/1 with unknown" do
    message_frame = <<0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82>>
    assert [
      %PgSiphon.Message{
        payload: <<0, 83, 69, 76, 69, 67, 84, 32, 42, 32,
          70, 82>>,
        type: "U",
        length: 12
      }
    ] = PgSiphon.Message.decode(message_frame)
  end

  test "parse/1 with extras" do
    message_frame = <<80, 0, 0, 0, 28, 0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82, 79, 77, 32, 110, 97, 109, 101, 115, 59, 0, 0, 0, 68, 0, 0, 0, 6, 83, 0, 72, 0, 0, 0, 4, 80, 0, 0, 0, 28, 0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82>>
    assert [
      %PgSiphon.Message{
        payload: <<0, 83, 69, 76, 69, 67, 84, 32, 42, 32,
          70, 82, 79, 77, 32, 110, 97, 109, 101, 115, 59, 0,
          0, 0>>,
        type: "P",
        length: 28
      },
      %PgSiphon.Message{
        payload: <<0>>,
        type: "D",
        length: 2
      },
      %PgSiphon.Message{payload: "", type: "H", length: 4},
      %PgSiphon.Message{
        payload: <<80, 0, 0, 0, 28, 0, 83, 69, 76, 69, 67,
          84, 32, 42, 32, 70, 82>>,
        type: "U",
        length: 17
      }
    ] = PgSiphon.Message.decode(message_frame)
  end
end
