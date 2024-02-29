defmodule Proba.Native do
  @moduledoc false

  use Rustler, otp_app: :proba, crate: "proba"

  # milliseconds
  @timeout 350

  @spec odds([String.t()], [String.t()], integer) :: [{}]
  def odds(_hands, _board, _iterations), do: error()

  @spec probability([String.t()], [String.t()], integer, integer) :: [{}]
  def probability(hands, board \\ [], precision \\ 0, iterations \\ 1_000_000) do
    {probabilities, _} =
      :rpc.multicall(
        [Node.self() | Node.list()],
        __MODULE__,
        :odds,
        [hands, board, iterations],
        @timeout
      )

    probabilities |> reduce |> format(iterations, precision)
  end

  def reduce(probabilities) do
    probabilities
    |> List.flatten()
    |> Enum.group_by(fn {hand, _, _} -> hand end, fn {_, win, tie} -> {win, tie} end)
    |> Enum.map(fn {hand, wins_and_ties} ->
      {hand,
       Enum.reduce(wins_and_ties, {0, 0}, fn {win, tie}, {w, t} ->
         {win / length(wins_and_ties) + w, tie / length(wins_and_ties) + t}
       end)}
    end)
  end

  def format(odds, iterations, precision) do
    Enum.map(odds, fn {hand, {wins, ties}} ->
      {
        hand,
        (wins * 100.0 / iterations) |> round(precision),
        (ties * 100.0 / iterations) |> round(precision)
      }
    end)
  end

  def round(float, precision \\ 0) do
    float |> Decimal.from_float() |> Decimal.round(precision, :floor)
  end

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
