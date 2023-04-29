defmodule Tachyon.Lobbies.ServerCreatedUpdatesTest do
  @moduledoc """
    // Standard updates
    updated: {
        response: Type.Object({}, { additionalProperties: true }),
    },
    joined: {
        response: Type.Object({}, { additionalProperties: true }),
    },
    add_user: {
        response: Type.Object({}, { additionalProperties: true }),
    },
    remove_user: {
        response: Type.Object({}, { additionalProperties: true }),
    },
    bot_added: {
        response: Type.Object({}, { additionalProperties: true }),
    },
    bot_updated: {
        response: Type.Object({}, { additionalProperties: true }),
    },
    bot_removed: {
        response: Type.Object({}, { additionalProperties: true }),
    },

    // Server updates, should be behind a listener
    opened: {
        response: Type.Object({}, { additionalProperties: true }),
    },
    closed: {
        response: Type.Object({}, { additionalProperties: true }),
    },
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  test "status" do
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
end
