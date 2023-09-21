defmodule Tachyon.LobbyCommands.BalanceCommandsTest do
  @moduledoc """
  Tests consul commands
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  # status s y n follow joinq leaveq splitlobby afks roll players password? explain newlobby jazlobby tournament

  test "status" do
    {:ok, host} = new_connection()
    lobby = create_lobby(host)
    # host_id = whoami(host)["id"]

    {:ok, balance_state} = WebHelper.get_server_state("balance", lobby["id"])
    assert balance_state["hashes"] == %{}

    {:ok, client1} = new_connection()
    _lobby_resp = join_lobby(client1, host, lobby["id"])
    client1_id = whoami(client1)["id"]

    {:ok, client2} = new_connection()
    _lobby_resp = join_lobby(client2, host, lobby["id"])
    client2_id = whoami(client2)["id"]

    {:ok, client3} = new_connection()
    _lobby_resp = join_lobby(client3, host, lobby["id"])
    client3_id = whoami(client3)["id"]

    {:ok, client4} = new_connection()
    _lobby_resp = join_lobby(client4, host, lobby["id"])
    client4_id = whoami(client4)["id"]

    WebHelper.set_user_rating(client1_id, "Team", 20, 1)
    WebHelper.set_user_rating(client2_id, "Team", 22, 1)
    WebHelper.set_user_rating(client3_id, "Team", 24, 1)
    WebHelper.set_user_rating(client4_id, "Team", 25, 1)

    empty_messages([host, client1, client2, client3, client4])

    lobby_say(host, "$makebalance")

    {:ok, balance_state} = WebHelper.get_server_state("balance", lobby["id"])
    current_balance = balance_state["current_balance"]
    assert current_balance["team_players"] == %{}
    assert current_balance["team_sizes"] == %{}

    # Now put them on teams and call it again
    update_status(client1, %{"is_player" => true})
    update_status(client2, %{"is_player" => true})
    update_status(client3, %{"is_player" => true})
    update_status(client4, %{"is_player" => true})

    # Let the player list cache update
    :timer.sleep(500)

    empty_messages([host, client1, client2, client3, client4])

    lobby_say(host, "$makebalance")

    {:ok, balance_state} = WebHelper.get_server_state("balance", lobby["id"])
    current_balance = balance_state["current_balance"]
    # First pick is random so it could be either team
    assert current_balance["team_players"] == %{"1" => [client3_id, client2_id], "2" => [client4_id, client1_id]} or current_balance["team_players"] == %{"2" => [client3_id, client2_id], "1" => [client4_id, client1_id]}
    assert current_balance["team_sizes"] == %{"1" => 2, "2" => 2}

    disconnect(client1)
    disconnect(client2)
    disconnect(client3)
    disconnect(client4)
    disconnect(host)

  end
end
