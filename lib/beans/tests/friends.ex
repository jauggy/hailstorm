defmodule Beans.Tests.Friends do
  @moduledoc """
  Tests adding and removing friends.
  """
  use Beans.Tachyon

  defp user_params(i) do
    %{
      email: "friends_#{i}",
      name: "friends_#{i}"
    }
  end

  @spec perform :: :ok | {:failure, String.t()}
  def perform() do
    [
      {socket1, user1},
      {socket2, user2},
      {socket3, user3},
      {socket4, user4}
    ] = 1..4
      |> Enum.map(fn i ->
        {:ok, socket, user} = new_connection(user_params(i))
        {socket, user}
      end)

    # Add but don't accept just yet
    add_friend(socket1, user2.id)

    {friends, requests} = get_friend_and_request_ids(socket1)
    assert(friends == [], "user1 has added no friends but their friend list is non-empty")
    assert(requests == [], "user1 has added no requests but their requests list is non-empty")

    {friends, requests} = get_friend_and_request_ids(socket2)
    assert(friends == [], "user2 has added no friends but their friend list is non-empty")
    assert(requests == [user1.id], "user2 should only have user1 as a requested friend")

    # Now accept
    accept_friend(socket2, user1.id)

    assert(get_friend_ids(socket1) == [user2.id], "user1 has been accepted but user2 does not appear in user2's friend list")
    assert(get_friend_ids(socket2) == [user1.id], "user1 has been accepted but user1 does not appear in user2's friend list")

    # Add new friends
    add_friend(socket1, user3.id)
    add_friend(socket1, user4.id)

    # Decline one and accept the other
    decline_friend(socket3, user1.id)
    accept_friend(socket4, user1.id)

    assert(get_friend_ids(socket1) == [user4.id, user2.id], "user4 has accepted user1 but hasn't appeared in user1's friend list")
    assert(get_friend_ids(socket4) == [user1.id], "user4 has accepted user1 but cannot see user1 in their friend list")

    # Finally we test removal
    remove_friend(socket4, user1.id)

    assert(get_friend_ids(socket1) == [user2.id], "user1's friends are incorrect after user4 removes them as a friend")

    # What happens if we remove the last user, a weird edge case?
    # Note this time we are testing socket1 removing a friend
    remove_friend(socket1, user2.id)
    assert(get_friend_ids(socket1) == [], "user1 removed their last friend yet their friend list is not empty")
  end

  @spec add_friend(Tachyon.sslsocket, non_neg_integer()) :: :ok
  defp add_friend(socket, userid) do
    tachyon_send(socket, %{
      cmd: "c.user.add_friend",
      user_id: userid
    })
    :timer.sleep(50)
  end

  @spec accept_friend(Tachyon.sslsocket, non_neg_integer()) :: :ok
  defp accept_friend(socket, userid) do
    tachyon_send(socket, %{
      cmd: "c.user.accept_friend_request",
      user_id: userid
    })
    :timer.sleep(50)
  end

  @spec decline_friend(Tachyon.sslsocket, non_neg_integer()) :: :ok
  defp decline_friend(socket, userid) do
    tachyon_send(socket, %{
      cmd: "c.user.decline_friend",
      user_id: userid
    })
    :timer.sleep(50)
  end

  @spec remove_friend(Tachyon.sslsocket, non_neg_integer()) :: :ok
  defp remove_friend(socket, userid) do
    tachyon_send(socket, %{
      cmd: "c.user.remove_friend",
      user_id: userid
    })
    :timer.sleep(50)
  end

  @spec get_friend_ids(Tachyon.sslsocket) :: [non_neg_integer()]
  defp get_friend_ids(socket) do
    tachyon_recv_until(socket)

    tachyon_send(socket, %{
      cmd: "c.user.list_friend_ids"
    })

    [reply] = tachyon_recv(socket)
    reply["friend_id_list"]
  end

  @spec get_friend_and_request_ids(Tachyon.sslsocket) :: {[non_neg_integer()], [non_neg_integer()]}
  defp get_friend_and_request_ids(socket) do
    tachyon_recv_until(socket)

    tachyon_send(socket, %{
      cmd: "c.user.list_friend_ids"
    })

    [reply] = tachyon_recv(socket)
    {reply["friend_id_list"], reply["request_id_list"]}
  end
end
