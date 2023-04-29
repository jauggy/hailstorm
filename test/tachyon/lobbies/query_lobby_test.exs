defmodule Tachyon.Lobbies.ListLobbyTest do
  @moduledoc """
  Tests consul commands
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  test "list lobby" do
    {:ok, host} = new_connection()
    lobby = create_lobby(host)

    {:ok, client} = new_connection()

    cmd = %{
      "command" => "lobby/join/request",
      "data" => %{
        "lobby_id" => lobby["id"]
      }
    }
    messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "lobby/join/response"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    assert response["data"]["result"] == "waiting_on_host"
    # validate!(response)

    :timer.sleep(1_000)

    assert true
  end

  test "get lobby" do

  end
end
