defmodule Proba.Native do
  @moduledoc false
  @type hand() :: String.t()
  @type board() :: [String.t()]

  use Rustler, otp_app: :proba, crate: "proba"
  require Logger

  # milliseconds
  @timeout 1000
  @iterations 1_000_000
  @suits ~w(s h d c)a

  @spec odds([hand], board, integer) :: [{}]
  def odds(_hands, _board, _iterations \\ @iterations), do: error()

  @spec heads_up([hand], board) :: [{}]
  def heads_up([hero | opponents] = hands, board \\ []) do
    variate(opponents)
    |> Enum.reject(fn villain -> used?(villain, [hero | board]) end)
    |> Task.async_stream(Proba.Native, :probability, [[hero], board],
      ordered: false,
      on_timeout: :kill_task,
      max_concurrency: length(Node.list()) + 1,
      timeout: @timeout
    )
    |> collect_successes
    |> group_by_hand(
      hands
      |> upcase
      |> Enum.flat_map(fn hand -> %{hand => variate(hand)} end)
      |> invert
    )
  end

  def multiway([hand | opponents] = hands, board \\ []) do
    probability(hand, opponents, board)
    |> group_by_hand(hands |> Enum.map(fn hand -> {hand, hand} end) |> Enum.into(%{}))
  end

  @spec probability(hand, [hand], board) :: [{}]
  def probability(hand, opponents, board \\ []) do
    node = Enum.random([Node.self() | Node.list()])
    Logger.info("Invoke on #{node}: hand: #{hand}, opponents: #{chunk(opponents)}, board: #{chunk(board)}")
    :erpc.call(
      node,
      __MODULE__,
      :odds,
      [[hand | opponents], board]
    )
  end

  defp collect_successes(results) do
    results
    |> Stream.flat_map(fn
      {:ok, result} -> result
      _ -> []
    end)
  end

  defp used?(hand, hands) do
    chunk(hand) |> Enum.any?(fn card -> card in chunk(hands) end)
  end

  defp variate(<<rank1::binary-size(1), "?", rank2::binary-size(1), "?">>) do
    for suit1 <- @suits,
        suit2 <- @suits,
        !(rank1 == rank2 && suit1 == suit2),
        do: "#{rank1}#{suit1}#{rank2}#{suit2}"
  end

  defp variate(<<rank1::binary-size(1), "x", rank2::binary-size(1), "x">>) do
    for suit <- @suits, rank1 != rank2, into: [], do: "#{rank1}#{suit}#{rank2}#{suit}"
  end

  defp variate(<<rank1::binary-size(1), "o", rank2::binary-size(1), "o">>) do
    for suit1 <- @suits, suit2 <- @suits, suit1 != suit2, do: "#{rank1}#{suit1}#{rank2}#{suit2}"
  end

  defp variate([head | tail]), do: (variate(head) ++ variate(tail)) |> Enum.uniq()
  defp variate([]), do: []
  defp variate(v) when byte_size(v) > 4, do: chunk(v, 4) |> variate
  defp variate(v), do: [v]

  defp upcase(hands) when is_list(hands), do: Enum.map(hands, &upcase/1)

  defp upcase(<<
         rank1::binary-size(1),
         suit1::binary-size(1),
         rank2::binary-size(1),
         suit2::binary-size(1)
       >>) do
    <<String.upcase(rank1)::binary, suit1::binary, String.upcase(rank2)::binary, suit2::binary>>
  end

  defp chunk(input, size \\ 2)

  defp chunk(hands, size) when is_list(hands) do
    chunk(Enum.join(hands, " "), size)
  end

  defp chunk(hand, size) do
    hand
    |> String.codepoints()
    |> Enum.chunk_every(size)
    |> Enum.map(&Enum.join/1)
  end

  defp invert(map) do
    for {k, values} <- map, v <- values, into: %{}, do: {v, k}
  end

  defp group_by_hand(probabilities, variants) do
    probabilities
    |> Enum.group_by(fn {hand, _, _} -> variants[hand] end)
    |> Enum.map(fn {hand, wins_and_ties} -> {hand, average(wins_and_ties)} end)
  end

  defp average(results) do
    {win_sum, tie_sum} =
      Enum.reduce(results, {0, 0}, fn {_, win, tie}, {wins, ties} -> {wins + win, ties + tie} end)

    {win_sum / length(results) * 100 / @iterations, tie_sum / length(results) * 100 / @iterations}
  end

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
