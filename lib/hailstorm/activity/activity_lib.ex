defmodule Hailstorm.Activity.ActivityLib do
  @moduledoc false
  use Hailstorm.TachyonHelper

  @spec make_new_agent(String.t(), String.t()) :: {pid(), pid()}
  def make_new_agent(name, email) do
    {:ok, {ws, ls}} = new_connection(%{
      name: name,
      email: email
    })

    agent = {ws, ls}
    userid = whoami(agent) |> Map.get("id")

    send(ls, {:set_forward, self()})

    {agent, userid}
  end
end
