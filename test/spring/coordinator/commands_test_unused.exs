defmodule Spring.Coordinator.CommandsTest do
  use ExUnit.Case, async: true
  use Hailstorm.SpringHelper

  test "no_command" do
    name = "no_command"
    socket = new_connection(%{name: name, email: name})

    Commands.send_dm(socket, "Coordinator", "$no_command_here or here")
    :timer.sleep(100)

    results = spring_recv_until(socket)
    assert results =~ "SAYPRIVATE Coordinator $no_command_here or here"

    # Now non-existent command
    Commands.send_dm(socket, "Coordinator", "$creativecommandname")
    :timer.sleep(100)

    results = spring_recv_until(socket)
    assert results =~ "SAYPRIVATE Coordinator $creativecommandname"
    assert results =~ "SAIDPRIVATE Coordinator No command of name 'creativecommandname'"
  end
end
