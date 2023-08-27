defmodule Hailstorm.Tests.BasicWebTest do
  @moduledoc """
  Tests the Ping command
  """
  use ExUnit.Case, async: true
  use Hailstorm.WebHelper

  test "test responses" do
    # Test the 404 part
    resp = get("/this_path_does_not_exist")
    assert resp.status_code == 404

    # Assert we'll raise a 404 with our helper functions
    assert_raise RuntimeError, fn -> get_html("/this_path_does_not_exist") end

    # Now check the site as a whole works as expected, we should be forwarded to the login screen
    resp = get("/")
    assert resp.status_code == 302
    location = resp.headers |> Map.new |> Map.get("location")
    assert location == "/login"

    resp = get("/login")
    assert resp.status_code == 200

    resp = get_html("/login")
    assert resp =~ "<div class=\"row\" style=\"padding-top: 15vh;\" id=\"login-div\">"
  end
end
