defmodule Spring.Consul.CommandsTest do

  use ExUnit.Case, async: true
  use Hailstorm.SpringHelper
  require Logger

  test "default balancer" do
    host_name = "balancer_host"
    username = "PlayfulRoseRecluse"

    host_socket =
      new_connection(%{
        name: host_name,
        roles: ["Bot"],
        update: %{
          bot: true
        }
      })

    user_socket =
      new_connection(%{
        name: username
      })

    # TeiServer will create a user but change the name by adding _hailstorm
    username = username <> "_hailstorm"

    lobby_id = Commands.open_lobby(host_socket, host_name, name: "lobby name")

    Commands.join_lobby(user_socket, username, host_socket, lobby_id)

    # This changes the user to be in team 1
    # Search TeiServer repo for that weird number 4195330
    spring_send(user_socket, "MYBATTLESTATUS 4195330 123456")

    # Make them boss
    Commands.send_lobby_message(host_socket, "Boss mode enabled for #{username}")

    # Remove randomness when balancing
    Commands.send_lobby_message(host_socket, "$set fuzz_multiplier 0")

    Commands.send_lobby_message(host_socket, "$makebalance")

    messages =
      host_socket
      |> spring_recv_until

    matches=Regex.scan(~r/Coordinator Picked #{username} for team \d, adding 16\.67 points for new total of 16\.67/, messages)

    # Check that balance was performed
    assert length(matches) >= 1


  end

  test "split_one_chevs balancer" do
    host_name = "balancer_host"
    username = "PlayfulRoseRecluse"

    host_socket =
      new_connection(%{
        name: host_name,
        roles: ["Bot"],
        update: %{
          bot: true
        }
      })

    user_socket =
      new_connection(%{
        name: username
      })

    # TeiServer will create a user but change the name by adding _hailstorm
    username = username <> "_hailstorm"

    lobby_id = Commands.open_lobby(host_socket, host_name, name: "lobby name")

    Commands.join_lobby(user_socket, username, host_socket, lobby_id)

    # This changes the user to be in team 1
    # Search TeiServer repo for that weird number 4195330
    spring_send(user_socket, "MYBATTLESTATUS 4195330 123456")

    # Make them boss
    Commands.send_lobby_message(host_socket, "Boss mode enabled for #{username}")

    # Remove randomness when balancing
    Commands.send_lobby_message(host_socket, "$set fuzz_multiplier 0")
    Commands.send_lobby_message(host_socket, "$balancemode split_one_chevs")
    Commands.send_lobby_message(host_socket, "$makebalance")

    messages =
      host_socket
      |> spring_recv_until

     # Check that balance was performed
    assert messages
           |> String.contains?(
             "Begin split_one_chevs balance"
           ) == true


  end
end
