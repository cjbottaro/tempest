alias Tempest.{Topology, Processor, Stats, Router}
alias Tempest.ProcessorLib.{FileReader, Counter, Printer}
alias WordCount.Scrubber

[ file_name | _ ] = System.argv

# Input is a line and emits words.
defmodule WordCount.Scrubber do
  use Processor

  def process(context, line) do
    Regex.replace(~r/[^'A-Za-z0-9]/, line, " ")
      |> String.downcase
      |> String.split(" ")
      |> Enum.map(&String.strip/1)
      |> Enum.filter(&(&1 != ""))
      |> Enum.map(&emit(context, &1))
  end
end

tuple_to_string = fn {count, word} ->
  "#{word} #{count}"
end

Topology.new
  |> Topology.add_processor(:reader, FileReader)
  |> Topology.add_processor(:scrubber, Scrubber, concurrency: 4)
  |> Topology.add_processor(:counter, Counter, router: Router.Group)
  |> Topology.add_processor(:printer, Printer, fn: tuple_to_string)

  |> Topology.add_link(:reader,   :scrubber)
  |> Topology.add_link(:scrubber, :counter)
  |> Topology.add_link(:counter,  :printer)

  |> Topology.begin_computation
  |> Topology.emit(:reader, file_name)
  |> Topology.end_computation

  |> Stats.get
  |> Stats.pretty_print
