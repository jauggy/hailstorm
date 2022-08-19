defmodule Mix.Tasks.Beans do
  use Mix.Task
  require Logger

  def run(_args) do
    Mix.Task.run("app.start")
    start_time = System.system_time(:millisecond)

    Beans.list_tests()
      |> Map.new(fn m ->
        task = Task.async(fn -> m.perform() end)

        {m, task}
      end)

    :timer.sleep(500)

    result = await_result()
    finish_time = System.system_time(:millisecond)

    post_process_results(result, finish_time - start_time)
  end

  defp await_result() do
    case Beans.call_server(:collector, :get_result) do
      {:ok, results} -> results
      {:waiting, _remaining} ->
        # Logger.info("remaining = #{remaining}")
        :timer.sleep(500)
        await_result()
    end
  end

  defp post_process_results(results, time_taken) do
    errors = results
      |> Enum.filter(fn {_m, result} -> result != :ok end)

    error_count = Enum.count(errors)
    test_count = Enum.count(results)

    IO.puts "Finished in #{time_taken}ms"

    case error_count do
      0 ->
        IO.puts(IO.ANSI.format([:green, "#{test_count} tests, 0 failures"]))

      1 ->
        IO.puts(IO.ANSI.format([:red, "#{test_count} tests, 1 failure"]))

      e ->
        IO.puts(IO.ANSI.format([:red, "#{test_count} tests, #{e} failures"]))
    end
  end
end
