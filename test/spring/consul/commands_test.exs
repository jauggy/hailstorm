defmodule Spring.Consul.CommandsTest do
  use ExUnit.Case, async: true
  use Hailstorm.SpringHelper

  test "bad-commands" do
    host = new_connection(%{
      name: "bad_command_host",
      update: %{
        bot: true
      }
    })
    user = new_connection(%{
      name: "bad_command_user"
    })

    lobby_id = Commands.open_lobby(host, "bad_command_host", name: "consul-command-test-bad-commands")
    Commands.join_lobby(user, "bad_command_user_hailstorm", host, lobby_id)
    spring_recv_until(user)

    # Non-existant command
    Commands.send_lobby_message(user, "$creativecommandname")

    messages = user
      |> spring_recv_until
      |> String.split("\n")

    assert Enum.member?(messages, "SAIDBATTLEEX Coordinator No command of name 'creativecommandname'")

    # Non-allowed command
    Commands.send_lobby_message(user, "$specunready")

    messages = user
      |> spring_recv_until
      |> String.split("\n")

    assert Enum.member?(messages, "SAIDBATTLEEX Coordinator You are not allowed to use the 'specunready' command (host only)")
  end
end
