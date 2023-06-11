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
        "type" => "property-key",
        "value" => "property-value",
        "hash" => "123456"
      }
    }
    messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "telemetry/property/response"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    assert response == %{
      "command" => "telemetry/property/response",
      "data" => %{},
      "status" => "success"
    }
    validate!(response)
  end
end
