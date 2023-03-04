defmodule Spring.Protocol.FriendTest do
  use ExUnit.Case, async: true
  use Hailstorm.SpringHelper

  test "connect" do
    [
      {socket1, user1},
      {socket2, user2},
      {socket3, user3},
      {socket4, user4}
    ] = 1..4
      |> Enum.map(fn i ->
        name = "friends_#{i}"
        {:ok, socket} = new_connection(%{name: name})

        {socket, name <> "_hailstorm"}
      end)

    # Add but don't accept just yet
    Commands.add_friend(socket1, user2)

    friends = Commands.get_friend_names(socket1)
    assert friends == [], "user1 has added no friends but their friend list is non-empty\n\t#{inspect friends}"

    requests = Commands.get_friend_request_names(socket1)
    assert requests == [], "user1 has added no requests but their requests list is non-empty\n\t#{inspect requests}"

    requests = Commands.get_friend_request_names(socket2)
    assert requests == [user1], "user2 should only have user1 as a requested friend\n\t#{inspect requests}"

    friends = Commands.get_friend_names(socket2)
    assert friends == [], "user2 has added no friends but their friend list is non-empty\n\t#{inspect friends}"

    requests = Commands.get_friend_request_names(socket2)
    assert requests == [user1], "user2 should only have user1 as a requested friend\n\t#{inspect requests}"

    # Now accept
    Commands.accept_friend(socket2, user1)

    result = Commands.get_friend_names(socket1)
    assert result == [user2], "user1 has been accepted but user2 does not appear in user2's friend list\n\t#{inspect result}"

    result = Commands.get_friend_names(socket2)
    assert result == [user1], "user1 has been accepted but user1 does not appear in user2's friend list\n\t#{inspect result}"

    # Add new friends
    Commands.add_friend(socket1, user3)
    Commands.add_friend(socket1, user4)

    # Decline one and accept the other
    Commands.decline_friend(socket3, user1)
    Commands.accept_friend(socket4, user1)

    result = Commands.get_friend_names(socket1)
    assert result == [user4, user2], "user4 has accepted user1 but hasn't appeared in user1's friend list\n\t#{result}"

    result = Commands.get_friend_names(socket4)
    assert result == [user1], "user4 has accepted user1 but cannot see user1 in their friend list\n\t#{result}"

    # Finally we test removal
    Commands.remove_friend(socket4, user1)

    result = Commands.get_friend_names(socket1)
    assert result == [user2], "user1's friends are incorrect after user4 removes them as a friend\n\t#{inspect result}"

    # What happens if we remove the last user, a weird edge case?
    # Note this time we are testing socket1 removing a friend
    Commands.remove_friend(socket1, user2)
    result = Commands.get_friend_names(socket1)
    assert result == [], "user1 removed their last friend yet their friend list is not empty\n\t#{inspect result}"
  end
end
