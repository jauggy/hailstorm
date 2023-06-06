defmodule Spring.Protocol.OpenBattleTest do
  use ExUnit.Case, async: true
  use Hailstorm.SpringHelper

  test "connect" do
    socket = new_connection(%{name: "open_battle_tester", roles: ["Bot"]})

    # Open the battle
    spring_send(socket, "OPENBATTLE 0 0 * 8452 8 -1 0 -1 Spring\t105.1.1-1767-gaaf2cc3 BAR105\tTabula_Remake 1.5\tbattleTest\tBeyond All Reason test-23183-6915e87")

    responses = socket
      |> spring_recv_until
      |> split_commands
      |> Map.new

    openbattleline = responses["OPENBATTLE"]
    battleopenedline = responses["BATTLEOPENED"]

    case openbattleline do
      [lobby_id_str] ->
        [opened_id] = battleopenedline

        assert opened_id == lobby_id_str
      _ ->
        raise "OpenBattle failed"
    end
  end
end
