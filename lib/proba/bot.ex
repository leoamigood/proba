defmodule Proba.Bot do
  @moduledoc false

  @bot :proba
  @precision 0

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  alias Proba.Native, as: Poker

  command("start")
  command("help", description: "Print the bot's help")
  command("odds", description: "Calculate hands win and tie percentage")

  middleware(ExGram.Middleware.IgnoreUsername)

  def bot, do: @bot

  def handle({:command, :start, _msg}, context) do
    answer(
      context,
      "This bot calculates poker hands odds given players hands and cards on the board. Use /help for more info."
    )
  end

  def handle({:command, :help, _msg}, context) do
    answer(context, "Examples: /odds AsKs QdQc or /odds Th9h Ac2c 8c7d6d3c")
  end

  def handle({:command, :odds, %{text: ""} = msg}, context) do
    handle({:command, :help, msg}, context)
  end

  def handle({:command, :odds, %{text: cards} = msg}, context) do
    handle({:text, cards, msg}, context)
  end

  def handle({:text, text, _msg}, context) do
    with :ok <- validate_cards(text),
         :ok <- validate_hands(text),
         :ok <- validate_players(text),
         :ok <- validate_board(text),
         :ok <- validate_duplicates(text) do
      {hands, board} = hands_and_board(text)
      answer(context, calculate(hands, board))
    else
      {:error, :invalid_cards, cards} ->
        answer(context, "Abort, invalid cards: #{cards |> Enum.join(" ")}")

      {:error, :invalid_hands, cards} ->
        answer(context, "Abort, invalid hands: #{cards |> Enum.join(" ")}")

      {:error, :invalid_players} ->
        answer(context, "Abort, over 10 player hands detected.")

      {:error, :invalid_board} ->
        answer(context, "Abort, over 5 board cards detected.")

      {:error, :duplicates, duplicates} ->
        answer(context, "Abort, duplicate cards: #{duplicates |> Enum.join(" ")}")
    end
  end

  defp as_cards(text) do
    text
    |> String.replace(" ", "")
    |> String.codepoints()
    |> Enum.chunk_every(2)
    |> Enum.map(fn [c, s] -> String.upcase(c) <> String.downcase(s) end)
    |> Enum.to_list()
  end

  defp validate_card(card) do
    case card |> String.split("", trim: true) do
      [rank | [suit]]
      when rank in ~w(A K Q J T 9 8 7 6 5 4 3 2) and suit in ~w(s h d c) ->
        :ok

      _ ->
        :error
    end
  end

  def validate_cards(text) do
    cards = text |> as_cards

    case cards |> Enum.filter(fn card -> validate_card(card) == :error end) do
      [] -> :ok
      outliers -> {:error, :invalid_cards, outliers}
    end
  end

  def validate_hands(text) do
    [board | hands] = text |> String.split() |> Enum.reverse()

    if board?(board),
      do: validate_hand_length(hands),
      else: validate_hand_length([board | hands])
  end

  defp validate_hand_length(hands) do
    case hands |> Enum.filter(fn card -> String.length(card) != 4 end) do
      [] -> :ok
      outliers -> {:error, :invalid_hands, outliers |> Enum.reverse()}
    end
  end

  defp board?(board), do: String.length(board) >= 6 and rem(String.length(board), 2) == 0

  defp validate_max(hands, max),
    do: if(length(hands) > max, do: {:error, :invalid_players}, else: :ok)

  def validate_players(text) do
    [board | hands] = text |> String.split() |> Enum.reverse()
    if board?(board), do: validate_max(hands, 10), else: validate_max(hands, 9)
  end

  def validate_board(text) do
    [board | _] = text |> String.split() |> Enum.reverse()
    if String.length(board) > 10, do: {:error, :invalid_board}, else: :ok
  end

  @spec validate_duplicates(String.t()) :: :ok | {:error, :duplicates, list}
  def validate_duplicates(text) do
    cards = text |> as_cards

    case Enum.uniq(cards -- Enum.uniq(cards)) do
      [] -> :ok
      list -> {:error, :duplicates, list}
    end
  end

  def hands_and_board(text) do
    [board | hands] = text |> String.split() |> Enum.reverse()

    if board?(board) do
      {
        hands |> Enum.reverse(),
        board |> as_cards
      }
    else
      {[board | hands] |> Enum.reverse(), []}
    end
  end

  @spec calculate([String.t()], [[String.t()]]) :: String.t()
  def calculate(cards, board \\ [])
  def calculate([_hero | [_opponent]] = cards, board) do
    cards
    |> Poker.heads_up(board)
    |> format
  end

  @spec calculate([String.t()], [String.t()]) :: String.t()
  def calculate(cards, board) do
    cards
    |> Poker.multiway(board)
    |> format
  end

  defp format(odds) do
    Enum.map(odds, fn {hand, {wins, ties}} ->
      {
        hand |> beautify,
        round(wins, @precision),
        round(ties, @precision)
      }
    end)
    |> Enum.map_join("\n", fn {hand, win, tie} ->
      "#{hand}#{report(" WINS:", win)}#{report(" TIES:", tie)}"
    end)
  end

  defp beautify(hands) when is_list(hands) do
    hands |> Enum.join(" ") |> beautify
  end

  defp beautify(hand) do
    String.replace(hand, ["s", "h", "d", "c"], fn
      "s" -> "♠"
      "h" -> "♥"
      "d" -> "♦"
      "c" -> "♣"
    end)
  end

  defp round(float, precision) do
    float |> Decimal.from_float() |> Decimal.round(precision, :floor)
  end

  defp report(_, 0), do: ""
  defp report(message, percent), do: "#{message} #{percent}%"
end
