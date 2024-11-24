defmodule Proba.BotTest do
  use ExUnit.Case

  alias Proba.Bot

  test "responds to /odds command with correct calculations" do
    %ExGram.Cnt{answers: [response: answer]} =
      Bot.handle({:command, :odds, %{text: "AsKs 8s8h"}}, %ExGram.Cnt{})

    assert String.contains?(answer.text, "8♠8♥ WINS: 52%")
    assert String.contains?(answer.text, "A♠K♠ WINS: 47%")
  end

  test "responds to /vary command with correct calculations" do
    %ExGram.Cnt{answers: [response: answer]} =
      Bot.handle({:command, :vary, %{text: "8s9s AxKx AxQx"}}, %ExGram.Cnt{})

    assert String.contains?(answer.text, "AxKx AxQx WINS: 62%")
    assert String.contains?(answer.text, "8♠9♠ WINS: 37%")
  end

  test "succeeds cards validation" do
    assert Bot.validate_cards("As9h") == :ok
    assert Bot.validate_cards("Ad2c As9d 8cTcJh") == :ok
  end

  test "fails cards validation" do
    assert Bot.validate_cards("AsBs") == {:error, :invalid_cards, ["Bs"]}
    assert Bot.validate_cards("Ad2c As9r 8cTcJ2") == {:error, :invalid_cards, ["9r", "J2"]}
  end

  test "succeeds hands validation" do
    assert Bot.validate_hands("As9h") == :ok
    assert Bot.validate_hands("Ad2c As9d 8cTcJh") == :ok
  end

  test "fails hands validation" do
    assert Bot.validate_hands("AsA d") == {:error, :invalid_hands, ["AsA", "d"]}
    assert Bot.validate_hands("AsA dAh9h") == {:error, :invalid_hands, ["AsA", "dAh9h"]}
    assert Bot.validate_hands("AsAdAh9h 2d3d4s") == {:error, :invalid_hands, ["AsAdAh9h"]}
    assert Bot.validate_hands("AsA dAh9h 2d3d4s") == {:error, :invalid_hands, ["AsA", "dAh9h"]}

    assert Bot.validate_hands("TsTd 9s9d 8s8d 7s7d 6s6 d5s5d 4s4d3s") ==
             {:error, :invalid_hands, ["6s6", "d5s5d"]}

    assert Bot.validate_hands("AsA dAh9h 2d3d4s5") ==
             {:error, :invalid_hands, ["AsA", "dAh9h", "2d3d4s5"]}
  end

  test "succeeds duplicate cards validation" do
    assert Bot.validate_cards("AsAd") == :ok
    assert Bot.validate_cards("Ad2c As9c 8cTcJh") == :ok
  end

  test "fails duplicate cards validation" do
    assert Bot.validate_duplicates("AsAd As9d 2cTs2c") == {:error, :duplicates, ["As", "2c"]}
  end

  test "fails duplicate cards validation case insensitive" do
    assert Bot.validate_duplicates("KcQs Ac6d kcJcaC") == {:error, :duplicates, ["Kc", "Ac"]}
  end

  test "succeeds max players validation" do
    assert Bot.validate_players("AsAd KsKd QsQd JsJd TsTd 9s9d 8s8d 7s7d 6s6d 5s5d") == :ok
  end

  test "fails max players validation" do
    assert Bot.validate_players("AsAd KsKd QsQd JsJd TsTd 9s9d 8s8d 7s7d 6s6d 5s5d 4s4d") ==
             {:error, :invalid_players}
  end

  test "succeeds max board cards validation" do
    assert Bot.validate_board("AsAd KsKd QsQd 2s3s4s5s6s") == :ok
  end

  test "fails max board cards validation" do
    assert Bot.validate_board("AsAd KsKd QsQd 2s3s4s5s6s7s") == {:error, :invalid_board}
  end

  test "parses hands and board" do
    assert Bot.hands_and_board("AsAd As9d") == {["AsAd", "As9d"], []}
    assert Bot.hands_and_board("AsAd As9d 2cTs2s") == {["AsAd", "As9d"], ["2c", "Ts", "2s"]}
  end

  #  @tag :skip
  test "calculates exact poker hands odds" do
    assert String.contains?(Bot.calculate(["AsKs", "8h8c"], []), "A♠K♠ WINS: 47%")
    assert String.contains?(Bot.calculate(["AsKs", "8h8c"], []), "8♥8♣ WINS: 52%")

    assert String.contains?(
             Bot.calculate(["As9s", "Ah9d"], ["2h", "9h", "2d"]),
             "A♠9♠ WINS: 0% TIES: 95%"
           )

    assert String.contains?(
             Bot.calculate(["As9s", "Ah9d"], ["2h", "9h", "2d"]),
             "A♥9♦ WINS: 4% TIES: 95%"
           )

    assert String.contains?(Bot.calculate(["AdQh", "2c2s", "8s9c"], []), "A♦Q♥ WINS: 40%")
    assert String.contains?(Bot.calculate(["AdQh", "2c2s", "8s9c"], []), "2♣2♠ WINS: 27%")
    assert String.contains?(Bot.calculate(["AdQh", "2c2s", "8s9c"], []), "8♠9♣ WINS: 32%")
  end

  test "calculates variative poker hands odds" do
    assert String.contains?(
             Bot.calculate(["AsKs", ["7?7?", "8?8?", "9?9?"]], []),
             "A♠K♠ WINS: 47%"
           )

    assert String.contains?(
             Bot.calculate(["AsKs", ["7?7?", "8?8?", "9?9?"]], []),
             "7?7? 8?8? 9?9? WINS: 52%"
           )

    assert String.contains?(
             Bot.calculate(["8s9s", ["AxKx", "AxQx", "AxJx"]], []),
             "8♠9♠ WINS: 37%"
           )

    assert String.contains?(
             Bot.calculate(["8s9s", ["AxKx", "AxQx", "AxJx"]], []),
             "AxKx AxQx AxJx WINS: 61%"
           )

    assert String.contains?(
             Bot.calculate(["8s9s", ["AoKo", "T?T?", "AxJx"]], []),
             "8♠9♠ WINS: 30%"
           )

    assert String.contains?(
             Bot.calculate(["8s9s", ["AoKo", "T?T?", "AxJx"]], []),
             "AoKo T?T? AxJx WINS: 69%"
           )
  end

  test "calculates poker hands odds case insensitive" do
    assert String.contains?(Bot.calculate(["asks", "8h8c"], []), "A♠K♠ WINS: 47%")
    assert String.contains?(Bot.calculate(["asks", "8h8c"], []), "8♥8♣ WINS: 52%")

    assert String.contains?(Bot.calculate(["asks", "aoto"], []), "A♠K♠ WINS: 72%")
    assert String.contains?(Bot.calculate(["asks", "aoto"], []), "AoTo WINS: 22%")
  end
end
