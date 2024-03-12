defmodule Spring.Consul.CommandsTest do
  use ExUnit.Case, async: true
  use Hailstorm.SpringHelper

  test "bad-commands" do
    host_socket = new_connection(%{
      name: "bad_command_host",
      roles: ["Bot"],
      update: %{
        bot: true
      }
    })
    user_socket = new_connection(%{
      name: "bad_command_user"
    })

    lobby_id = Commands.open_lobby(host_socket, "bad_command_host", name: "consul-command-test-bad-commands")
    Commands.join_lobby(user_socket, "bad_command_user_hailstorm", host_socket, lobby_id)
    spring_recv_until(user_socket)

    # Non-existant command
    Commands.send_lobby_message(host_socket, "Boss mode enabled for bad_command_host")

    messages = user_socket
      |> spring_recv_until
      |> String.split("\n")


    # Non-allowed command
    Commands.send_lobby_message(host_socket, "$specunready")

    messages = user_socket
      |> spring_recv_until
      |> String.split("\n")

    assert Enum.member?(messages, "SAIDBATTLEEX Coordinator You are not allowed to use the 'specunready' command (host only)")
  end
end
