defmodule Teiserver.Spring.FriendTest do
  use ExUnit.Case, async: true
  use Beans.SpringHelper

  defp user_params(i) do
    %{
      email: "friends_#{i}",
      name: "friends_#{i}"
    }
  end

  test "connect" do
    [
      {socket1, user1},
      {socket2, user2},
      {socket3, user3},
      {socket4, user4}
    ] = 1..4
      |> Enum.map(fn i ->
        user = user_params(i)
        {:ok, socket} = new_connection(user)
        user = %{
          name: user.name <> "_beans",
          email: user.email
        }

        {socket, user}
      end)

    # Add but don't accept just yet
    add_friend(socket1, user2.name)

    friends = get_friend_names(socket1)
    assert friends == [], "user1 has added no friends but their friend list is non-empty\n\t#{inspect friends}"

    requests = get_friend_request_names(socket1)
    assert requests == [], "user1 has added no requests but their requests list is non-empty\n\t#{inspect requests}"

    requests = get_friend_request_names(socket2)
    assert requests == [user1.name], "user2 should only have user1 as a requested friend\n\t#{inspect requests}"

    friends = get_friend_names(socket2)
    assert friends == [], "user2 has added no friends but their friend list is non-empty\n\t#{inspect friends}"

    requests = get_friend_request_names(socket2)
    assert requests == [user1.name], "user2 should only have user1 as a requested friend\n\t#{inspect requests}"

    # Now accept
    accept_friend(socket2, user1.name)

    result = get_friend_names(socket1)
    assert result == [user2.name], "user1 has been accepted but user2 does not appear in user2's friend list\n\t#{inspect result}"

    result = get_friend_names(socket2)
    assert result == [user1.name], "user1 has been accepted but user1 does not appear in user2's friend list\n\t#{inspect result}"

    # Add new friends
    add_friend(socket1, user3.name)
    add_friend(socket1, user4.name)

    # Decline one and accept the other
    decline_friend(socket3, user1.name)
    accept_friend(socket4, user1.name)

    result = get_friend_names(socket1)
    assert result == [user4.name, user2.name], "user4 has accepted user1 but hasn't appeared in user1's friend list\n\t#{result}"

    result = get_friend_names(socket4)
    assert result == [user1.name], "user4 has accepted user1 but cannot see user1 in their friend list\n\t#{result}"

    # Finally we test removal
    remove_friend(socket4, user1.name)

    result = get_friend_names(socket1)
    assert result == [user2.name], "user1's friends are incorrect after user4 removes them as a friend\n\t#{inspect result}"

    # What happens if we remove the last user, a weird edge case?
    # Note this time we are testing socket1 removing a friend
    remove_friend(socket1, user2.name)
    result = get_friend_names(socket1)
    assert result == [], "user1 removed their last friend yet their friend list is not empty\n\t#{inspect result}"
  end

  @spec add_friend(Spring.sslsocket, String.t()) :: :ok
  defp add_friend(socket, name) do
    spring_send(socket, "FRIENDREQUEST userName=#{name}")
    :timer.sleep(50)
  end

  @spec accept_friend(Spring.sslsocket, String.t()) :: :ok
  defp accept_friend(socket, name) do
    spring_send(socket, "ACCEPTFRIENDREQUEST userName=#{name}")
    :timer.sleep(50)
  end

  @spec decline_friend(Spring.sslsocket, String.t()) :: :ok
  defp decline_friend(socket, name) do
    spring_send(socket, "DECLINEFRIENDREQUEST userName=#{name}")
    :timer.sleep(50)
  end

  @spec remove_friend(Spring.sslsocket, String.t()) :: :ok
  defp remove_friend(socket, name) do
    spring_send(socket, "UNFRIEND userName=#{name}")
    :timer.sleep(50)
  end

  @spec get_friend_names(Spring.sslsocket) :: [String.t()]
  defp get_friend_names(socket) do
    spring_recv_until(socket)

    spring_send(socket, "FRIENDLIST")

    spring_recv(socket)
      |> String.replace("FRIENDLISTBEGIN", "")
      |> String.replace("FRIENDLISTEND", "")
      |> String.trim()
      |> String.split("\n")
      |> Enum.reject(fn r -> r == "" end)
      |> Enum.map(fn line ->
        "FRIENDLIST userName=" <> name = line
        String.trim(name)
      end)
  end

  @spec get_friend_request_names(Spring.sslsocket) :: [String.t()]
  defp get_friend_request_names(socket) do
    spring_recv_until(socket)

    spring_send(socket, "FRIENDREQUESTLIST")

    spring_recv_until(socket)
      |> String.replace("FRIENDREQUESTLISTBEGIN", "")
      |> String.replace("FRIENDREQUESTLISTEND", "")
      |> String.trim()
      |> String.split("\n")
      |> Enum.reject(fn r -> r == "" end)
      |> Enum.map(fn line ->
        "FRIENDREQUESTLIST userName=" <> name = line
        String.trim(name)
      end)
  end
end
