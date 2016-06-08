alias Tempest.{Topology, Processor, Stats, Router}

[ file_name | _ ] = System.argv

defmodule WordCount.Scrubber do
  use Tempest.Processor
  def process(context, word) do
    Regex.replace(~r/[^'A-Za-z0-9]/, word, " ")
      |> String.downcase
      |> String.split(" ")
      |> Enum.map(&String.strip/1)
      |> Enum.filter(&(&1 != ""))
      |> Enum.map(&emit(context, &1))
  end
end

topology = Topology.new
  |> Topology.add_processor( :reader,   Processor.FileReader, emit: :lines         )
  |> Topology.add_processor( :scrubber, WordCount.Scrubber,   concurrency: 10                       )
  |> Topology.add_processor( :counter,  Processor.Counter,    concurrency: 1, router: Router.Group )
  |> Topology.add_processor( :printer,  Processor.Printer                                          )

  |> Topology.add_link(:reader,   :scrubber)
  |> Topology.add_link(:scrubber, :counter)
  |> Topology.add_link(:counter,  :printer)

  |> Topology.begin_computation
  |> Topology.emit(:reader, file_name)
  |> Topology.end_computation

  |> Stats.get
  |> Stats.pretty_print
