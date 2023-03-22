defmodule Mix.Tasks.Hailstorm.Springload do
  @moduledoc """
  Run with mix hailstorm.springload

  --module=status

  -m : metric monitor
  -p : ping_pong user
  """

  use Mix.Task

  @spec run(list()) :: :ok
  def run(raw_args) do
    {kwargs, _args, _invalid} = OptionParser.parse(
      raw_args,
      aliases: [
        p: :pingpong,
        m: :monitor
      ],
      strict: [
        monitor: :boolean,
        pingpong: :boolean,
        module: :string
      ]
    )

    # IO.puts ""
    # IO.inspect args
    # IO.inspect kwargs
    # IO.puts ""

    user_module = case kwargs[:module] do
      "status" -> Hailstorm.SpringLoad.MystatusUser
      m -> raise "No --module handler for '#{m}'"
    end

    Mix.Task.run("app.start")

    if kwargs[:monitor] do
      {:ok, _pid} = DynamicSupervisor.start_child(Hailstorm.MonitorSupervisor, {
        Hailstorm.Servers.MetricServer,
        name: "metric_server",
        data: %{}
      })
    end

    if kwargs[:pingpong] do
      {:ok, _pid} = DynamicSupervisor.start_child(Hailstorm.MonitorSupervisor, {
        Hailstorm.SpringLoad.PingPongUser,
        name: "ping_pong",
        data: %{
          name: "hs_pingpong",
          email: "hs_pingpong@hailstorm",
        }
      })
    end

    0..3#10_000
    |> Enum.each(fn i ->
      name = "hs_springload_#{i}"
      email = "hs_springload_#{i}@hailstorm"

      {:ok, _pid} = DynamicSupervisor.start_child(Hailstorm.SpringSupervisor, {
        user_module,
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
