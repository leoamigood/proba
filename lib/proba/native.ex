defmodule Proba.Native do
  @moduledoc false

  use Rustler, otp_app: :proba, crate: "proba"

  @spec odds([String.t()], [String.t()], integer) :: [{}]
  def odds(_hands, _board, _iterations), do: error()

  @spec probability([String.t()], [String.t()], integer) :: [{}]
  def probability(hands, board \\ [], iterations \\ 1_000_000) do
    odds(hands, board, iterations)
    |> Enum.map(fn {hand, wins, ties} ->
      {
        hand,
        (wins * 100.0 / iterations) |> format,
        (ties * 100.0 / iterations) |> format
      }
    end)
  end

  defp format(float) do
    float |> Decimal.from_float() |> Decimal.round(0, :floor) |> Decimal.to_integer()
  end

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
