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

  @spec get(String.t()) :: String.t()
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

  defmacro __using__(_opts) do
    quote do
      import Beans.WebHelper, only: [
        get_html: 1,
        get: 1,
        # read_messages: 2,
        # pop_messages: 1,
        # pop_messages: 2,
        # new_connection: 1
      ]
      alias Beans.WebHelper
    end
  end
end
