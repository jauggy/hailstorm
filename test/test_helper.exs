ExUnit.start()

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

  _resp ->
    raise "Server not up, cannot start tests"
end

# Now to setup some configs we want a certain way
Hailstorm.WebHelper.set_hailstorm_config("teiserver.Username max length", "100")
