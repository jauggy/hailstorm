defmodule Tachyon.ConsulCommands.PublicCommandsTest do
  @moduledoc """
  Tests consul commands
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  # status s y n follow joinq leaveq splitlobby afks roll players password? explain newlobby jazlobby tournament

  test "status" do
    {:ok, host} = new_connection()
    lobby = create_lobby(host)

    {:ok, client} = new_connection()

    cmd = %{
      "command" => "account/who_am_i/request",
      "data" => %{}
    }
    messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "account/who_am_i/response"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    assert response["data"]["name"] == "whoami_hailstorm"
    validate!(response)
  end
end
