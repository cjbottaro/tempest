defmodule NullProcessor do
  use Tempest.Processor
end

defmodule TopologyTest do
  use ExUnit.Case
  doctest Tempest

  import Tempest.Topology

  test "building a topology" do
    import Enum, only: [at: 2]

    topology = new
      |> add_processor(:foo, NullProcessor)
      |> add_processor(:bar, NullProcessor)
      |> add_processor(:baz, NullProcessor, concurrency: 2)

      |> add_link(:foo, :bar)
      |> add_link(:foo, :baz)
      |> add_link(:bar, :baz)

    foo = topology.components[:foo]
    assert foo.concurrency == 1
    assert Process.alive?(foo.worker_pids |> at(0))

    bar = topology.components[:bar]
    assert bar.concurrency == 1
    assert Process.alive?(bar.worker_pids |> at(0))

    baz = topology.components[:baz]
    assert baz.concurrency == 2
    assert Process.alive?(baz.worker_pids |> at(0))
    assert Process.alive?(baz.worker_pids |> at(1))

    assert outgoing_links(topology, :foo) == [:bar, :baz]
    assert outgoing_links(topology, :bar) == [:baz]
    assert outgoing_links(topology, :baz) == []

    assert incoming_links(topology, :foo) == []
    assert incoming_links(topology, :bar) == [:foo]
    assert incoming_links(topology, :baz) == [:foo, :bar]
  end

end
