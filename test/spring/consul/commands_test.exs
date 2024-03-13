defmodule Spring.Consul.CommandsTest do
  use ExUnit.Case, async: true
  use Hailstorm.SpringHelper
  alias Hailstorm.TachyonHelper
  require Logger

  test "bad-commands" do
    host_socket =
      new_connection(%{
        name: "bad_command_host",
        roles: ["Bot"],
        update: %{
          bot: true
        }
      })

    user_socket =
      new_connection(%{
        name: "PlayfulRoseRecluse"
      })

    lobby_id =
      Commands.open_lobby(host_socket, "bad_command_host",
        name: "consul-command-test-bad-commands"
      )

    Commands.join_lobby(user_socket, "PlayfulRoseRecluse_hailstorm", host_socket, lobby_id)
    spring_recv_until(user_socket)
    spring_send(user_socket, "MYBATTLESTATUS 4195330 123456")

    messages =
      user_socket
      |> spring_recv_until

    # Non-existant command
    Commands.send_lobby_message(host_socket, "Boss mode enabled for PlayfulRoseRecluse_hailstorm")

    messages =
      host_socket
      |> spring_recv_until

    TachyonHelper.tachyon_send(host_socket, %{cmd: "c.lobby.message", message: "$set fuzz_multiplier 0"})



    Commands.send_lobby_message(host_socket, "$makebalance")

    messages =
      host_socket
      |> spring_recv_until

    Logger.info(messages)

    # Check that balance was performed
    assert messages
           |> String.contains?(
             "Coordinator Picked PlayfulRoseRecluse_hailstorm for team 1, adding 16.48 points for new total of 16.48"
           ) == true

    Commands.send_lobby_message(host_socket, "$status")

    messages =
      host_socket
      |> spring_recv_until

    Logger.info(messages)
  end
end
