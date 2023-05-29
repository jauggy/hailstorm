defmodule Tachyon.Telemetry.PropertiesTest do
  @moduledoc """
  Tests consul commands
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  test "property" do
    {:ok, client} = new_connection()

    cmd = %{
      "command" => "telemetry/property/request",
      "data" => %{
        "key" => "property-key",
        "value" => "property-value"
      }
    }
    messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "telemetry/property/response"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    assert response["data"]["result"] == "success"
    assert response["data"]["key"] == "property-type"
    validate!(response)
  end
end
