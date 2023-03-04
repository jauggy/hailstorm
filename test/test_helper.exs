ExUnit.start()

# Before we run any tests lets ensure the test server is actually running
url = [
  Application.get_env(:beans, Beans)[:host_web_url],
  "teiserver/api/beans/up"
] |> Enum.join("/")

case HTTPoison.post(url, "", [{"Content-Type", "application/json"}]) do
  {:ok, _resp} ->
    true
  _resp ->
    raise "Server not up, cannot start tests"
end
