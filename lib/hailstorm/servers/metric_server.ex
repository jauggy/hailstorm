defmodule Hailstorm.Servers.MetricServer do
  use GenServer
  alias Phoenix.PubSub

  @tick_period 1_000

  @impl true
  def handle_info(:tick, state) do
    new_state = state
      |> calculate_metrics()
      |> report_metrics()
      |> reset_counters()

    {:noreply, new_state}
  end

  def handle_info({:increment, counter}, state) do
    current = Map.get(state.counters, counter, 0)
    new_counters = Map.put(state.counters, counter, current + 1)
    {:noreply, %{state | counters: new_counters}}
  end

  def handle_info({:measure, key, value}, state) do
    new_measure = [value | Map.get(state.measures, key, [])]
    new_measures = Map.put(state.measures, key, new_measure)
    {:noreply, %{state | measures: new_measures}}
  end

  @impl true
  def handle_info({:spring_messages_sent, _userid, server_count, _batch_count, client_count}, state) do
    {:noreply, %{state |
      spring_server_messages_sent: state.spring_server_messages_sent + server_count,
      spring_client_messages_sent: state.spring_client_messages_sent + client_count,
    }}
  end

  @impl true
  def handle_call(:get_metrics, _from, %{metrics: metrics} = state) do
    {:reply, metrics, state}
  end

  defp calculate_metrics(state) do
    metrics = %{}

    state
    |> Map.put(:metrics, metrics)
  end

  defp report_metrics(state) do
    IO.puts ""
    IO.inspect state.metrics
    IO.puts ""

    PubSub.broadcast(
      Hailstorm.PubSub,
      "report_metrics",
      state.metrics
    )
    state
  end

  defp reset_counters(state) do
    %{
      metrics: state.metrics,
      counters: %{},
      measures: %{}
    }
  end

  # Startup
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:data])
  end

  @impl true
  def init(_opts) do
    :timer.send_interval(@tick_period, self(), :tick)
    :ok = PubSub.subscribe(Hailstorm.PubSub, "metric_reports")

    {:ok, reset_counters(%{metrics: %{}})}
  end
end
