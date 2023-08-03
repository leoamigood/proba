defmodule Proba.Native do
  use Rustler, otp_app: :proba, crate: "proba"

  @spec odds([String], [String], integer) :: [{}]
  def odds(_hands, _board, _iterations), do: error()

  def probability(hands, board \\ [], iterations \\ 1_000_000) do
    odds(hands, board, iterations)
    |> Enum.map(fn {hand, wins, ties} ->
      {
        hand,
        "WINS: #{wins * 100.0 / iterations |> Decimal.from_float |> Decimal.round(0, :floor)}%",
        "TIES: #{ties * 100.0 / iterations |> Decimal.from_float |> Decimal.round(0, :floor)}%"
      }
    end)
  end

  defp error(), do: :erlang.nif_error(:nif_not_loaded)
end
