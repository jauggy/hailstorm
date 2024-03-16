defmodule Spring.Balance.BalanceTest do
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
    # Is there a better way to add a user to a team?
    spring_send(user_socket, "MYBATTLESTATUS 4195330 123456")

    # Make them boss
    Commands.send_lobby_message(host_socket, "Boss mode enabled for #{username}")

    # Remove randomness when balancing
    Commands.send_lobby_message(host_socket, "$set fuzz_multiplier 0")

    Commands.send_lobby_message(host_socket, "$makebalance")

    messages =
      host_socket
      |> spring_recv_until

    matches =
      Regex.scan(
        ~r/Coordinator Picked #{username} for team \d, adding 16\.67 points for new total of 16\.67/,
        messages
      )

    # Check that balance was performed
    assert length(matches) >= 1
  end

  @doc """
  This tests the balance mode split_one_chevs
  This will sort players by OS descending, but place 1 chevs at the bottom
  See TeiServer repo for full documentation
  """
  test "split_one_chevs balancer" do
    host_name = "balancer_host"
    noob1 = "Noob1_hailstorm"
    noob2 = "Noob2_hailstorm"
    pro1 = "Pro1_hailstorm"
    pro2 = "Pro2_hailstorm"

    host_socket =
      new_connection(%{
        name: host_name,
        roles: ["Bot"],
        update: %{
          bot: true
        }
      })

    # Noobs will have play time 0 to give rank 0
    noob1_socket =
      new_connection(%{
        name: noob1,
        player_minutes: 0
      })

    noob2_socket =
      new_connection(%{
        name: noob2,
        player_minutes: 0
      })

    # Pros will have playtime of 6 hours or more. Minutes less than 60 are ignored due to rounding
    pro1_socket =
      new_connection(%{
        name: pro1,
        player_minutes: 6 * 60
      })

    pro2_socket =
      new_connection(%{
        name: pro2,
        player_minutes: 1000 * 60
      })

    # TeiServer will create a user but change the name by adding _hailstorm

    lobby_id = Commands.open_lobby(host_socket, host_name, name: "lobby name")

    Commands.join_lobby(noob1_socket, noob1, host_socket, lobby_id)
    Commands.join_lobby(noob2_socket, noob2, host_socket, lobby_id)
    Commands.join_lobby(pro1_socket, pro1, host_socket, lobby_id)
    Commands.join_lobby(pro2_socket, pro2, host_socket, lobby_id)

    # This changes the user to be in team 1
    # Search TeiServer repo for that weird number 4195330
    # Is there a better way to add a user to a team?
    spring_send(noob1_socket, "MYBATTLESTATUS 4195330 123456")
    spring_send(noob2_socket, "MYBATTLESTATUS 4195330 123456")
    spring_send(pro1_socket, "MYBATTLESTATUS 4195330 123456")
    spring_send(pro2_socket, "MYBATTLESTATUS 4195330 123456")

    # Make them boss
    Commands.send_lobby_message(host_socket, "Boss mode enabled for #{noob1}")

    # Remove randomness when balancing
    Commands.send_lobby_message(host_socket, "$set fuzz_multiplier 0")
    Commands.send_lobby_message(host_socket, "$balancemode split_one_chevs")

    #Read messages to clear them
    host_socket
    |> spring_recv_until

    #Now balance
    Commands.send_lobby_message(host_socket, "$makebalance")

    messages =
      host_socket
      |> spring_recv_until

    Logger.debug(messages)

    # Check that balance was performed
    assert messages
           |> String.contains?("Begin split_one_chevs balance") == true

    # Check that pros were picked first and noobs picked last. There should be one noob per team.
    assert messages
           |> String.contains?(
             "Pro2_hailstorm (Chev: 5) picked for Team 1\nPro1_hailstorm (Chev: 2) picked for Team 2\nNoob2_hailstorm (Chev: 1) picked for Team 2\nNoob1_hailstorm (Chev: 1) picked for Team 1"
           )

   end
end
