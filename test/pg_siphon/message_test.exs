defmodule PgSiphon.MessageTest do
  use ExUnit.Case

  test "parse/1 with P -> DSH messages" do
    message_frame =
      <<80, 0, 0, 0, 28, 0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82, 79, 77, 32, 110, 97, 109,
        101, 115, 59, 0, 0, 0, 68, 0, 0, 0, 6, 83, 0, 72, 0, 0, 0, 4>>

    assert [
             %PgSiphon.Message{
               payload:
                 <<0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82, 79, 77, 32, 110, 97, 109, 101,
                   115, 59, 0, 0, 0>>,
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
    message_frame =
      <<66, 0, 0, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 69, 0, 0, 0, 9, 0, 0, 0, 0, 0, 67, 0, 0, 0,
        6, 83, 0, 83, 0, 0, 0, 4>>

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

  test "parse/1 with sync message" do
    message_frame = <<83, 0, 0, 0, 4>>

    assert [%PgSiphon.Message{payload: "", type: "S", length: 4}] =
             PgSiphon.Message.decode(message_frame)
  end

  test "parse/1 with nil message" do
    message_frame = <<0, 0, 0, 8, 4, 210, 22, 47>>

    assert [%PgSiphon.Message{payload: <<4, 210, 22, 47>>, type: "ssl", length: 8}] =
             PgSiphon.Message.decode(message_frame)
  end

  test "decode/1 with unknown" do
    message_frame = <<0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82>>

    assert [
             %PgSiphon.Message{
               payload: <<0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82>>,
               type: "U",
               length: 12
             }
           ] = PgSiphon.Message.decode(message_frame)
  end

  test "parse/1 with extras" do
    message_frame =
      <<80, 0, 0, 0, 28, 0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82, 79, 77, 32, 110, 97, 109,
        101, 115, 59, 0, 0, 0, 68, 0, 0, 0, 6, 83, 0, 72, 0, 0, 0, 4, 80, 0, 0, 0, 28, 0, 83, 69,
        76, 69, 67, 84, 32, 42, 32, 70, 82>>

    assert [
             %PgSiphon.Message{
               payload:
                 <<0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82, 79, 77, 32, 110, 97, 109, 101,
                   115, 59, 0, 0, 0>>,
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
               payload: <<80, 0, 0, 0, 28, 0, 83, 69, 76, 69, 67, 84, 32, 42, 32, 70, 82>>,
               type: "U",
               length: 17
             }
           ] = PgSiphon.Message.decode(message_frame)
  end

  test "decode/1 with startup" do
    message_frame =
      <<22, 3, 1, 1, 67, 1, 0, 1, 63, 3, 3, 241, 171, 219, 4, 153, 166, 255, 140, 74, 237, 8, 218,
        55, 154, 19, 71, 26, 19, 63, 235, 208, 91, 156, 131, 213, 236, 148, 96, 42, 28, 225, 153,
        32, 199, 67, 235, 53, 105, 190, 224, 212, 184, 121, 0, 125, 66, 20, 154, 92, 143, 109,
        154, 188, 24, 31, 193, 80, 233, 255, 122, 92, 213, 183, 175, 208, 0, 62, 19, 2, 19, 3, 19,
        1, 192, 44, 192, 48, 0, 159, 204, 169, 204, 168, 204, 170, 192, 43, 192, 47, 0, 158, 192,
        36, 192, 40, 0, 107, 192, 35, 192, 39, 0, 103, 192, 10, 192, 20, 0, 57, 192, 9, 192, 19,
        0, 51, 0, 157, 0, 156, 0, 61, 0, 60, 0, 53, 0, 47, 0, 255, 1, 0, 0, 184, 0, 0, 0, 14, 0,
        12, 0, 0, 9, 108, 111, 99, 97, 108, 104, 111, 115, 116, 0, 11, 0, 4, 3, 0, 1, 2, 0, 10, 0,
        22, 0, 20, 0, 29, 0, 23, 0, 30, 0, 25, 0, 24, 1, 0, 1, 1, 1, 2, 1, 3, 1, 4, 0, 35, 0, 0,
        0, 16, 0, 13, 0, 11, 10, 112, 111, 115, 116, 103, 114, 101, 115, 113, 108, 0, 22, 0, 0, 0,
        23, 0, 0, 0, 13, 0, 42, 0, 40, 4, 3, 5, 3, 6, 3, 8, 7, 8, 8, 8, 9, 8, 10, 8, 11, 8, 4, 8,
        5, 8, 6, 4, 1, 5, 1, 6, 1, 3, 3, 3, 1, 3, 2, 4, 2, 5, 2, 6, 2, 0, 43, 0, 5, 4, 3, 4, 3, 3,
        0, 45, 0, 2, 1, 1, 0, 51, 0, 38, 0, 36, 0, 29, 0, 32, 249, 197, 21, 139, 150, 151, 248,
        121, 174, 116, 22, 76, 77, 51, 128, 113, 58, 200, 50, 235, 252, 228, 20, 207, 51, 141,
        225, 189, 163, 133, 13, 33>>

    assert [
             %PgSiphon.Message{
               payload: "Cannot process TLS messages",
               type: "tls_change_cypher",
               length: 328
             }
           ] = PgSiphon.Message.decode(message_frame)
  end
end
