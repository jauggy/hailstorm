defmodule Beans.Web do
  @spec server_exists? :: boolean
  def server_exists?() do
    url = [
      Application.get_env(:beans, Beans)[:host_api_url],
      "teiserver"
    ] |> Enum.join("/")

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{} = resp} ->
        resp.status_code == 302
      _ ->
        false
    end
  end
end
