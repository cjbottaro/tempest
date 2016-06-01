defmodule WordScrubber do
  use Tempest.Processor

  def process(topo, state, word) do
    word = Regex.replace(~r/[^'A-Za-z0-9]/, word, " ")
      |> String.downcase
      |> String.split(" ")
      |> Enum.map(&String.strip/1)
      |> Enum.filter(&(&1 != ""))
      |> Enum.map(&emit(topo, &1))

    state
  end

end
