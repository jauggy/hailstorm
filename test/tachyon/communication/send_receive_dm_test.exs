defmodule Tachyon.Communication.SendReceiveDMTest do
  @moduledoc """
  Tests consul commands
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  test "send and receive direct messages" do
    {:ok, conn1} = new_connection(%{name: "dm_user1"})
    {:ok, conn2} = new_connection(%{name: "dm_user2"})

    user1 = whoami(conn1)
    user2 = whoami(conn2)

    cmd = %{
      "command" => "communication/sendDirectMessage/request",
      "data" => %{
        "to" => user2["id"],
        "message" => "text goes here"
      }
    }
    messages = tachyon_send_and_receive(conn1, cmd, fn
      %{"command" => "communication/sendDirectMessage/response"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    assert response == %{
      "command" => "communication/sendDirectMessage/response",
      "data" => %{},
      "status" => "success"
    }
    validate!(response)

    # Now ensure we got the message with user2
    messages = tachyon_receive(conn2, fn
      %{"command" => "communication/receivedDirectMessage/response"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    assert response == %{
      "command" => "communication/receivedDirectMessage/response",
      "data" => %{"content" => "text goes here", "sender_id" => user1["id"]},
      "status" => "success"
    }
  end
end
