defmodule Mix.Tasks.Hailstorm.Connhold do
  @moduledoc """
  Run with mix hailstorm.connhold

  Creates a bunch of connections to the server, doesn't do anything with them.

  options:

  --url
    The url for the connections to open
  """

  use Mix.Task

  @spec run(list()) :: :ok
  def run(raw_args) do
    {kwargs, _args, _invalid} = OptionParser.parse(
      raw_args,
      strict: [
        url: :string
      ]
    )

    url = if kwargs[:url] do
      kwargs[:url] |> String.to_charlist()
    else
      Application.get_env(:hailstorm, Hailstorm)[:host_socket_url]
    end

    _ = 0..2000
    |> Enum.map(fn i ->
      IO.puts "#{i}"
      :timer.sleep(25)

      {:ok, _socket} = :ssl.connect(
        url,
        8201,
        active: false,
        verify: :verify_none
      )
    end)

    :timer.sleep(25_000)
  end
end
