defmodule Proba.Native do
  use Rustler, otp_app: :proba, crate: "proba"

  @spec odds([String], [String], integer) :: [{}]
  def odds(_hands, _board, _iterations \\ 1_000_000), do: error()

  defp error(), do: :erlang.nif_error(:nif_not_loaded)
end
