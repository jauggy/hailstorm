defmodule Mix.Tasks.Hailstorm.Springload do
  @moduledoc """
  Run with mix hailstorm.springload [ping | status]
  """

  use Mix.Task

  @spec run(list()) :: :ok
  def run(args) do
    user_type = case args do
      [] ->
        Hailstorm.SpringLoad.PingPongUser

      ["status" | _] ->
        Hailstorm.SpringLoad.MystatusUser

      ["ping" | _] ->
        Hailstorm.SpringLoad.PingPongUser
    end

    Mix.Task.run("app.start")

    0..3#10_000
    |> Enum.each(fn i ->
      IO.puts i

      name = "hs_springload_#{i}"
      email = "hs_springload_#{i}@hailstorm"

      {:ok, _pid} = DynamicSupervisor.start_child(Hailstorm.SpringSupervisor, {
        user_type,
        name: "springload_#{i}",
        data: %{
          name: name,
          email: email
        }
      })
    end)


    :timer.sleep(1000)
  end
end
