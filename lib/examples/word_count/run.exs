alias Tempest.Topology

[ file_name | _ ] = System.argv

topology = Topology.new
  |> Topology.add_processor(InputFileReader)
  |> Topology.add_processor(WordScrubber, 4)
  |> Topology.add_processor(WordCounter, 2)
  |> Topology.add_processor(ResultAggregator, 2)

topology = topology
  |> Topology.add_link(InputFileReader, WordScrubber)
  |> Topology.add_link(WordScrubber, WordCounter, :group)
  |> Topology.add_link(WordCounter, ResultAggregator)

topology = topology
  |> Topology.start
  |> Topology.emit(InputFileReader, file_name)
  |> Topology.finish
