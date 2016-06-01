defmodule WordCounter do
  use Tempest.Processor

  def process(topo, state, word) do
    Map.update state, word, 1, &(&1 + 1)
  end

  def done(topo, state) do
    Enum.each state, &(emit(topo, &1))
  end

end
