defmodule Hailstorm.ServerApi do
  @moduledoc """

  """

  alias Hailstorm.WebHelper

  @spec register_account(String.t(), String.t()) :: {:ok, non_neg_integer()}
  def register_account(username, email) do
    response = WebHelper.post("/teiserver/api/register", %{
      "user" => %{
        "name" => username,
        "email" => email,
        "password" => "password"
      }
    })

    case response do
      %HTTPoison.Response{status_code: 200} = response ->
        userid = response.body |> Jason.decode! |> Map.get("userid")
        {:ok, userid}

      %HTTPoison.Response{status_code: 400} = response ->
        raise response.body |> Jason.decode! |> Map.get("reason")

      _ ->
        IO.puts "Error response"
        IO.inspect response
        IO.puts ""
        raise "Bad response"
    end
  end
end
