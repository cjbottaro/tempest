alias Tempest.Topology
alias WordCount.{FileReader, LineProcessor, WordCounter, Summary}

[ file_name | _ ] = System.argv

topology = Topology.new
  |> Topology.add_processor(:reader, FileReader)
  |> Topology.add_processor(:lines, LineProcessor, concurrency: 4)
  |> Topology.add_processor(:counter, WordCounter, concurrency: 4, router: :group)
  |> Topology.add_processor(:summary, Summary)

  |> Topology.add_link(:reader, :lines)
  |> Topology.add_link(:lines, :counter)
  |> Topology.add_link(:counter, :summary)

  |> Topology.start

start_time = :os.system_time(:milli_seconds)

topology
  |> Topology.emit(:reader, file_name)
  |> Topology.stop

elapse_time = (:os.system_time(:milli_seconds) - start_time) / 1000.0

IO.puts "\nRuntime: #{elapse_time}"
