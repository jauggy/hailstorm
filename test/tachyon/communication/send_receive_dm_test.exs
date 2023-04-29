defmodule Tachyon.Communication.SendReceiveDMTest do
  @moduledoc """
  Tests consul commands
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  test "status" do
    {:ok, host} = new_connection()
    lobby = create_lobby(host)

    {:ok, client} = new_connection()

    cmd = %{
      "command" => "communication/send_direct_message/request",
      "data" => %{
        "to" => 123,
        "message" => "text goes here"
      }
    }
    messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "communication/send_direct_message/response"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    assert response["data"]["result"] == "success"
    validate!(response)
  end
end
