defmodule Hailstorm.Tachyon.ConnectionErrorTest do
  @moduledoc """
  Tests creating connections incorrectly, ensures we are sent
  the correct error messages.
  """
  use ExUnit.Case, async: true
  alias Hailstorm.{TachyonHelper, ListenerServer}
  alias Hailstorm.TachyonWsServer, as: Ws

  defp make_user_and_token() do
    params = TachyonHelper.cleanup_params(%{})

    :ok = TachyonHelper.create_user(params)
    :ok = TachyonHelper.update_user(params.email, Map.merge(%{verified: true}, params[:update] || %{
      friends: [],
      friend_requests: [],
      ignored: [],
      avoided: []
    }))
    {:ok, token} = TachyonHelper.get_token(params)

    token
  end

  test "400 missing params - application_hash" do
    token_value = make_user_and_token()

    query = URI.encode_query(%{
      "token" => token_value,
      "application_version" => "1.0.0",
      "application_name" => "Hailstorm"
    })
    url = Application.get_env(:hailstorm, Hailstorm)[:websocket_url] <> "?#{query}"

    listener = ListenerServer.new_listener()
    result = Ws.start_link(url, listener)

    assert result == {:error, %WebSockex.RequestError{code: 400, message: "Bad Request"}}
  end

  test "400 missing params - application_version" do
    token_value = make_user_and_token()

    query = URI.encode_query(%{
      "token" => token_value,
      "application_hash" => "HailstormHash",
      "application_name" => "Hailstorm"
    })
    url = Application.get_env(:hailstorm, Hailstorm)[:websocket_url] <> "?#{query}"

    listener = ListenerServer.new_listener()
    result = Ws.start_link(url, listener)

    assert result == {:error, %WebSockex.RequestError{code: 400, message: "Bad Request"}}
  end

  test "400 missing params - application_name" do
    token_value = make_user_and_token()

    query = URI.encode_query(%{
      "token" => token_value,
      "application_hash" => "HailstormHash",
      "application_version" => "1.0.0"
    })
    url = Application.get_env(:hailstorm, Hailstorm)[:websocket_url] <> "?#{query}"

    listener = ListenerServer.new_listener()
    result = Ws.start_link(url, listener)

    assert result == {:error, %WebSockex.RequestError{code: 400, message: "Bad Request"}}
  end

  test "400 missing params - token" do
    query = URI.encode_query(%{
      "application_hash" => "HailstormHash",
      "application_version" => "1.0.0",
      "application_name" => "Hailstorm"
    })
    url = Application.get_env(:hailstorm, Hailstorm)[:websocket_url] <> "?#{query}"

    listener = ListenerServer.new_listener()
    result = Ws.start_link(url, listener)

    assert result == {:error, %WebSockex.RequestError{code: 400, message: "Bad Request"}}
  end

  test "401 bad token" do
    query = URI.encode_query(%{
      "token" => "my-fake-token-value",
      "application_hash" => "HailstormHash",
      "application_version" => "1.0.0",
      "application_name" => "Hailstorm"
    })
    url = Application.get_env(:hailstorm, Hailstorm)[:websocket_url] <> "?#{query}"

    listener = ListenerServer.new_listener()
    result = Ws.start_link(url, listener)

    assert result == {:error, %WebSockex.RequestError{code: 401, message: "Unauthorized"}}
  end

  # Not sure how to replicate a 403 or 500
end
