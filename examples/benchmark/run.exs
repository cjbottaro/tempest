alias Tempest.{Topology, Stats}

# input --> repeater --> counter --\
# input --> repeater --> counter ---\
#                                    |--> summer
# input --> repeater --> counter ---/
# input --> repeater --> counter --/
topology = Topology.new
  |> Topology.add_processor(:input, RangeEmitter, concurrency: 4, router: :shuffle)
  |> Topology.add_processor(:repeater, Tempest.Processor.Identity, concurrency: 4)
  |> Topology.add_processor(:counter, Counter, concurrency: 4)
  |> Topology.add_processor(:summer, Summer)

  |> Topology.add_link(:input, :repeater)
  |> Topology.add_link(:repeater, :counter)
  |> Topology.add_link(:counter, :summer)
  |> Topology.start

  |> Topology.emit(:input, {1, 1_000_000})
  |> Topology.emit(:input, {1, 1_000_000})
  |> Topology.emit(:input, {1, 1_000_000})
  |> Topology.emit(:input, {1, 1_000_000})
  |> Topology.stop

  |> Stats.get
  |> Stats.pretty_print
