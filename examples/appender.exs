alias Tempest.{Topology, Processor, Stats}
alias Tempest.ProcessorLib.{FileReader, Printer}

[ file_name | _ ] = System.argv

defmodule Appender do
  use Processor

  option :suffix, required: true

  def process(context, message) do
    %{ suffix: suffix } = get_options(context)
    emit(context, "#{message}#{suffix}")
  end
end

topology = Topology.new
  |> Topology.add_processor(:reader, FileReader)
  |> Topology.add_processor(:appender, Appender, suffix: "!!", concurrency: 2)
  |> Topology.add_processor(:printer, Printer)

  |> Topology.add_link(:reader, :appender)
  |> Topology.add_link(:appender, :printer)

  |> Topology.begin_computation
  |> Topology.emit(:reader, file_name)
  |> Topology.end_computation

  |> Stats.get
  |> Stats.pretty_print
