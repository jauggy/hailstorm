# Adding new tests
## File location
Each test should live within [lib/hailstorm/tests](lib/hailstorm/tests) and be a `.ex` file named appropriately. Particularly complex tests where multiple files are needed should be given their own folder.

## Module name
Each test needs to have a module named using the format `Hailstorm.Tests.TestName` where `TestName` is replaced by the name of your test. You do not need to add your module name anywhere else, Hailstorm will automatically pick up on its existence and include it.

## Module requirements
Each module must include:
- `use Hailstorm.Tachyon`
- A function called `perform` with 0 arguments and returning either `:ok` for successful completion or a tuple of `{:failure, reason}` for unsuccessful completion or failure

Ideally the module will also include:
- A `@moduledoc` explaining what the test does

### Tachyon helper functions
The `use Hailstorm.Tachyon` call brings in several functions designed to help with these tests.

`new_connection/1`: Given a map containing at least email and name, it will create a new user on the server, verify the user and then log the user in. It will return a tuple of `{:ok, socket, user}`, the socket will be needed for the next functions. If you include an `:update` key of a map, this will be passed to the update user function. By default it is `%{verified: true}` and this will be merged with your map so you do not need to re-declare verified to be true.

`tachyon_send/2`: Given a socket and a map, it will send a command to the server.

`tachyon_recv/1`: Given a socket, it will listen for a response from the server. If one does not arrive within 500ms it will assume no response. Responses are placed in a list, an empty list will mean no responses. A response of `:closed` means the connection has closed.

`tachyon_recv_until/1`: Similar to the `tachyon_recv` command except it will keep waiting for a response until none arrive. This means as long as there is a stream of responses it will keep waiting.

## Example module
```elixir
defmodule Hailstorm.Tests.Example do
  @moduledoc """
  Documentation explaining the purpose of the test
  """
  use Hailstorm.Tachyon

  @example_user_params %{
    email: "example",
    name: "example",
  }

  @spec perform :: :ok | {:failure, String.t()}
  def perform() do
    with {:ok, socket, _user} <- new_connection(@example_user_params),
        :ok <- do_test(socket)
      do
        :ok
      else
        {:error, reason} -> {:failure, reason}
    end
  end

  @spec do_test(Tachyon.sslsocket) :: :ok | {:error, String.t()}
  defp do_test(socket) do
    tachyon_send(socket, %{
      cmd: "c.example.command"
    })

    case tachyon_recv(socket) do
      [] -> {:error, "No reply to example command"}
      [%{"cmd" => "s.expected.example_command"}] -> :ok
      _ -> {:error, "Unexpected response to example command"}
    end
  end
end
```
