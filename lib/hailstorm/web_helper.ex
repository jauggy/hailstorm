defmodule Hailstorm.WebHelper do
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
    url = Application.get_env(:hailstorm, Hailstorm)[:host_web_url] <> path
    HTTPoison.get(url)
  end

  @spec post(String.t(), map()) :: %HTTPoison.AsyncResponse{} | %HTTPoison.Response{}
  def post(path, body) do
    {:ok, resp} = do_post(path, body)
    resp
  end

  @spec do_post(String.t(), map()) ::
          {:error, HTTPoison.Error.t()}
          | {:ok, %HTTPoison.AsyncResponse{}}
          | {:ok, %HTTPoison.Response{}}
  def do_post(path, body) do
    body_json = Jason.encode!(body)
    url = Application.get_env(:hailstorm, Hailstorm)[:host_web_url] <> path
    headers = [{"Content-Type", "application/json"}]
    opts = []

    HTTPoison.post(url, body_json, headers, opts)
  end

  @spec set_hailstorm_config(String.t(), String.t()) :: :ok | {:error, String.t()}
  def set_hailstorm_config(key, value) do
    url = [
      Application.get_env(:hailstorm, Hailstorm)[:host_web_url],
      "teiserver/api/hailstorm/update_site_config"
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

  @spec set_user_rating(non_neg_integer(), String.t(), number(), number()) :: :ok | {:error, String.t()}
  def set_user_rating(userid, rating_type, skill, uncertainty) do
    url = [
      Application.get_env(:hailstorm, Hailstorm)[:host_web_url],
      "teiserver/api/hailstorm/update_user_rating"
    ] |> Enum.join("/")

    data = %{
      userid: userid,
      rating_type: rating_type,
      skill: skill,
      uncertainty: uncertainty
    } |> Jason.encode!

    result = case HTTPoison.post(url, data, [{"Content-Type", "application/json"}]) do
      {:ok, %{status_code: 201}} ->
        %{"result" => "success"}
      {:ok, resp} ->
        resp.body |> Jason.decode!
    end

    case result do
      %{"result" => "failure"} ->
        {:error, "Error updating user rating for '#{userid}'"}
      %{"result" => "success"} ->
        :ok
    end
  end

  @spec get_server_state(String.t(), non_neg_integer()) :: {:ok, map()} | {:error, String.t()}
  def get_server_state(server, id) do
    url = [
      Application.get_env(:hailstorm, Hailstorm)[:host_web_url],
      "teiserver/api/hailstorm/get_server_state"
    ] |> Enum.join("/")

    data = %{
      server: server,
      id: id
    } |> Jason.encode!

    case HTTPoison.post(url, data, [{"Content-Type", "application/json"}]) do
      {:ok, %{status_code: 201} = resp} ->
        {:ok, resp.body |> Jason.decode!}
      {:ok, resp} ->
        {:error, "Error updating getting server state for '#{server}/#{id}.\nResp body: #{resp.body}'"}
    end
  end

  defmacro __using__(_opts) do
    quote do
      import Hailstorm.WebHelper, only: [
        get_html: 1,
        get: 1
      ]
      alias Hailstorm.WebHelper
    end
  end
end
