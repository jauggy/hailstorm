defmodule Mix.Tasks.Beans do
  use Mix.Task

  @spec run(list()) :: :ok
  def run(_args) do
    if can_run?() do
      Mix.Task.run("app.start")
      start_time = System.system_time(:millisecond)

      Beans.list_tests()
        |> Map.new(fn m ->
          task = Task.async(fn ->
            Beans.register_module(m)
            result = m.perform()
            Beans.save_result(m, result)
          end)

          {m, task}
        end)

      :timer.sleep(500)

      result = await_result()
      finish_time = System.system_time(:millisecond)

      post_process_results(result, finish_time - start_time)
    end
  end

  defp can_run?() do
    test_server_exists()
  end

  defp test_server_exists() do
    if Beans.Tachyon.server_exists?() do
      true
    else
      IO.puts(IO.ANSI.format([:red, "Unable to connect to Teiserver instance, have you started it?"]))
      false
    end
  end

  defp await_result() do
    case Beans.call_server(:collector, :get_result) do
      {:ok, results} -> results
      {:waiting, _remaining} ->
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
