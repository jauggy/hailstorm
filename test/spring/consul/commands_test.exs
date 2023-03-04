defmodule Spring.Consul.CommandsTest do
  use ExUnit.Case, async: true
  use Beans.SpringHelper

  test "connect" do
    host = new_connection(%{
      name: "bad_command_host"
    })
    user = new_connection(%{
      name: "bad_command_user"
    })

    # Add but don't accept just yet
    # Commands.add_friend(socket1, user2.name)


  end
end
