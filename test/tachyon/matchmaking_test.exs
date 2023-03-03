# defmodule Beans.Tests.Matchmaking do
#   @moduledoc """
#   Tests adding and removing friends.
#   """
#   use Beans.Tachyon

#   defp user_params(i) do
#     %{
#       email: "matchmaking_#{i}",
#       name: "matchmaking_#{i}"
#     }
#   end

#   @spec perform :: :ok | {:failure, String.t()}
#   def perform() do
#     [
#       # Solo matchmakers
#       {socket1, user1},
#       {socket2, user2},
#       {socket3, user3},
#     ] = 1..3
#       |> Enum.map(fn i ->
#         {:ok, socket, user} = new_connection(user_params(i))
#         {socket, user}
#       end)


#   end
# end
