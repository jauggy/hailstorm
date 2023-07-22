defmodule Mix.Tasks.Hailstorm.FakeActivity do
  @moduledoc """
  Run with mix hailstorm.fake_activity

  Creates a selection of users and performs activity via Tachyon agents
  """

  use Mix.Task
  require Logger
  alias Hailstorm.Activity.{
    LobbyHostAgent,
    InOutAgent
  }

  @impl Mix.Task
  @spec run(list()) :: :ok
  def run(_raw_args) do
    # {kwargs, _args, _invalid} = OptionParser.parse(
    #   raw_args,
    #   aliases: [
    #     p: :pingpong,
    #     m: :monitor
    #   ],
    #   strict: [
    #     monitor: :boolean,
    #     pingpong: :boolean,
    #     module: :string
    #   ]
    # )

    Mix.Task.run("app.start")

    check_site_is_up()

    Logger.info("Starting agent connections")

    # start_agent(InOutAgent, "InOut1", %{})
    start_agent(LobbyHostAgent, "LobbyHost1", %{

    })

    :timer.sleep(100_000)
  end

  defp check_site_is_up() do
    # Before we run any tests lets ensure the test server is actually running
    url = [
      Application.get_env(:hailstorm, Hailstorm)[:host_web_url],
      "teiserver/api/hailstorm/start"
    ] |> Enum.join("/")

    case HTTPoison.post(url, "", [{"Content-Type", "application/json"}]) do
      {:ok, %{status_code: 201, body: body}} ->
        resp = Jason.decode!(body)

        if resp["up"] != true do
          raise "Server responded but is not up, cannot start tests"
        end

      {:error, %HTTPoison.Error{reason: :econnrefused, id: nil}} ->
        raise "Server not up, cannot start tests"

      resp ->
        IO.puts ""
        IO.inspect resp
        IO.puts ""
        raise "Server not up, cannot start tests"
    end
  end

  defp start_agent(module, name, params \\ %{}) do
    p_name = "#{name}-#{module}"

    {:ok, pid} =
        DynamicSupervisor.start_child(Hailstorm.AgentSupervisor, {
          module,
          name: p_name,
          data:
            Map.merge(
              %{
                name: name,
                p_name: p_name
              },
              params
            )
        })

    pid
  end
end
