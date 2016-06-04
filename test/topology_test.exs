defmodule NullProcessor do
  use Tempest.Processor
end

defmodule TopologyTest do
  use ExUnit.Case
  doctest Tempest

  import Tempest.Topology

  test "building a topology" do
    topology = new
      |> add_processor(:foo, NullProcessor)
      |> add_processor(:bar, NullProcessor)
      |> add_processor(:baz, NullProcessor, concurrency: 2)

      |> add_link(:foo, :bar)
      |> add_link(:foo, :baz)
      |> add_link(:bar, :baz)

    foo = topology.processors[:foo]
    assert foo.concurrency == 1
    assert Process.alive?(foo.pids[0])

    bar = topology.processors[:bar]
    assert bar.concurrency == 1
    assert Process.alive?(bar.pids[0])

    baz = topology.processors[:baz]
    assert baz.concurrency == 2
    assert Process.alive?(baz.pids[0])
    assert Process.alive?(baz.pids[1])

    assert outgoing_links(topology, :foo) == [:bar, :baz]
    assert outgoing_links(topology, :bar) == [:baz]
    assert outgoing_links(topology, :baz) == []

    assert incoming_links(topology, :foo) == []
    assert incoming_links(topology, :bar) == [:foo]
    assert incoming_links(topology, :baz) == [:foo, :bar]
  end

  test "starting a topology" do
    topology = new
      |> add_processor(:foo, NullProcessor)
      |> add_processor(:bar, NullProcessor, concurrency: 2)
      |> start

    Enum.each topology.processors, fn { name, processor } ->
      Enum.each processor.pids, fn { _, pid } ->
        %{ name: server_name } = GenServer.call(pid, :inspect)
        assert server_name == name
      end
    end
  end

  test "processors with default routing" do
    topology = new |> add_processor(:foo, NullProcessor, concurrency: 2)
    processor = topology.processors[:foo]
    router = processor.router

    assert %Tempest.Router.Random{} = router
    assert router.count == 2
    assert router.pids == processor.pids
  end

  test "processor with shuffle routing" do
    topology = new |> add_processor(:foo, NullProcessor, concurrency: 2, routing: :shuffle)
    processor = topology.processors[:foo]
    router = processor.router

    assert %Tempest.Router.Shuffle{} = router
    assert router.count == 2
    assert router.pids == processor.pids
  end

  test "processor with group routing" do
    topology = new |> add_processor(:foo, NullProcessor, concurrency: 2, routing: {:group, :func, &(&1.blah)})
    processor = topology.processors[:foo]
    router = processor.router

    assert %Tempest.Router.Group{} = router
    assert router.count == 2
    assert router.pids == processor.pids
    assert router.type == :func
    assert is_function(router.arg)
  end

end
