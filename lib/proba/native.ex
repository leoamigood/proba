defmodule Proba.Native do
  @moduledoc false

  use Rustler, otp_app: :proba, crate: "proba"

  # milliseconds
  @timeout 350

  @spec odds([String.t()], [String.t()], integer) :: [{}]
  def odds(_hands, _board, _iterations), do: error()

  @spec probability([String.t()], [String.t()], integer, integer) :: [{}]
  def probability(hands, board \\ [], precision \\ 0, iterations \\ 1_000_000) do
    {probabilities, _} = multicall(hands, board, iterations)
    probabilities |> reduce |> format(iterations, precision)
  end

  defp multicall(hands, board, iterations) do
    :rpc.multicall(
      [Node.self() | Node.list()],
      __MODULE__,
      :odds,
      [hands, board, iterations],
      @timeout
    )
  end

  defp reduce(probabilities) do
    probabilities
    |> List.flatten()
    |> Enum.group_by(fn {hand, _, _} -> hand end)
    |> Enum.map(fn {hand, wins_and_ties} -> {hand, average(wins_and_ties)} end)
  end

  defp average(results) do
    {win_sum, tie_sum} = Enum.reduce(results, {0, 0}, fn {_, win, tie}, {wins, ties} -> {wins + win, ties + tie} end)
    {win_sum / length(results), tie_sum / length(results)}
  end

  defp format(odds, iterations, precision) do
    Enum.map(odds, fn {hand, {wins, ties}} ->
      {
        hand,
        (wins * 100.0 / iterations) |> round(precision),
        (ties * 100.0 / iterations) |> round(precision)
      }
    end)
  end

  defp round(float, precision) do
    float |> Decimal.from_float() |> Decimal.round(precision, :floor)
  end

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
