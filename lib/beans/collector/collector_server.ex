defmodule Beans.Collector.CollectorServer do
  use GenServer


  def handle_call(:get_result, _from, %{remaining: []} = state) do
    {:reply, {:ok, state.tasks}, state}
  end

  def handle_call(:get_result, _from, %{remaining: remaining} = state) do
    {:reply, {:waiting, Enum.count(remaining)}, state}
  end

  def handle_cast({:complete, id, result}, state) do
    case result do
      :ok ->
        IO.puts(IO.ANSI.format([:green, "."]))
      {:failure, reason} ->
        IO.puts [
          "",
          "Failure in #{id}",
          IO.ANSI.format([:red, reason]),
          ""
        ] |> Enum.join("\n")
    end

    new_tasks = Map.put(state.tasks, id, result)
    new_remaining = List.delete(state.remaining, id)

    {:noreply, %{state | tasks: new_tasks, remaining: new_remaining}}
  end

  def handle_cast({:register, id}, state) do
    new_tasks = Map.put(state.tasks, id, nil)
    new_remaining = [id | state.remaining]

    {:noreply, %{state | tasks: new_tasks, remaining: new_remaining}}
  end
  def start_link(init_args) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    GenServer.start_link(__MODULE__, [init_args])
  end

  def init(_args) do
    Registry.register(
      Beans.Registry,
      :collector,
      nil
    )

    {:ok, %{
      tasks: %{},
      remaining: []
    }}
  end
end
