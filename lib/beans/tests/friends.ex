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
      # {socket3, user3},
      # {socket4, user4}
    ] = 1..2
      |> Enum.map(fn i ->
        {:ok, socket, user} = new_connection(user_params(i))
        {socket, user}
      end)

    add_friend(socket1, user2.id)
    accept_friend(socket2, user1.id)

    list1 = get_friend_ids(socket1)
    list2 = get_friend_ids(socket2)

    assert(list1 == [user2.id], "User 1 does not have User 2 as a friend")
    assert(list2 == [user1.id], "User 1 does not have User 2 as a friend")
  end

  @spec add_friend(Tachyon.sslsocket, non_neg_integer()) :: :ok
  defp add_friend(socket, userid) do
    tachyon_send(socket, %{
      cmd: "c.user.add_friend",
      user_id: userid
    })
  end

  @spec accept_friend(Tachyon.sslsocket, non_neg_integer()) :: :ok
  defp accept_friend(socket, userid) do
    tachyon_send(socket, %{
      cmd: "c.user.accept_friend",
      user_id: userid
    })
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
end
