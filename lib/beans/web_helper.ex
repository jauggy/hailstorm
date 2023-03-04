defmodule Beans.WebHelper do
  @spec get_html(String.t()) :: String.t()
  def get_html(path) do
    case do_get(path) do
      {:ok, %HTTPoison.Response{status_code: 200} = resp} ->
        resp.body
      _ ->
        raise "Bad response"
    end
  end

  @spec get(String.t()) :: %HTTPoison.AsyncResponse{} | %HTTPoison.Response{}
  def get(path) do
    {:ok, resp} = do_get(path)
    resp
  end

  @spec do_get(String.t()) ::
          {:error, HTTPoison.Error.t()}
          | {:ok, %HTTPoison.AsyncResponse{}}
          | {:ok, %HTTPoison.Response{}}
  def do_get(path) do
    url = Application.get_env(:beans, Beans)[:host_web_url] <> path
    HTTPoison.get(url)
  end

  @spec set_beans_config(String.t(), String.t()) :: :ok | {:error, String.t()}
  def set_beans_config(key, value) do
    url = [
      Application.get_env(:beans, Beans)[:host_web_url],
      "teiserver/api/beans/update_site_config"
    ] |> Enum.join("/")

    data = %{
      key: key,
      value: value
    } |> Jason.encode!

    result = case HTTPoison.post(url, data, [{"Content-Type", "application/json"}]) do
      {:ok, %{status_code: 201}} ->
        %{"result" => "success"}
      {:ok, resp} ->
        resp.body |> Jason.decode!
    end

    case result do
      %{"result" => "failure"} ->
        {:error, "Error updating site_config '#{key}' to '#{value}'"}
      %{"result" => "success"} ->
        :ok
    end
  end

  defmacro __using__(_opts) do
    quote do
      import Beans.WebHelper, only: [
        get_html: 1,
        get: 1,

        beans_request: 1
      ]
      alias Beans.WebHelper
    end
  end
end
