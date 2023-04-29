defmodule Tachyon.Telemetry.EventTest do
  @moduledoc """
  Tests consul commands
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  test "event" do
    {:ok, user} = new_connection()

    cmd = %{
      "command" => "telemetry/event/request",
      "data" => %{
        "type" => "event-type",
        "value" => %{
          "key1" => "v1",
          "key2" => "v2"
        }
      }
    }
    messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "telemetry/event/response"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    assert response["data"]["result"] == "success"
    assert response["data"]["type"] == "event-type"
    validate!(response)
  end
end
