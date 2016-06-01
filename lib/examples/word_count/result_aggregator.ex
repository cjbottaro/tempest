defmodule ResultAggregator do
  use Tempest.Processor

  def process(topo, state, { word, count }) do
    # IO.puts "#{inspect self} #{word} #{count}"
  end

end
