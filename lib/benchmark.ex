defmodule Benchmark do
  @moduledoc false

  require Logger
  alias Timex.Duration
  alias Timex.Format.Duration.Formatters.Humanized

  def measure(function) do
    {runtime, result} = function |> :timer.tc
    Logger.info "Execution time: #{runtime |> Duration.from_microseconds |> Humanized.format}"

    result
  end
end
