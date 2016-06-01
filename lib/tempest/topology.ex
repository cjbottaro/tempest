defmodule Tempest.Topology do
  defstruct [processors: %{}, links: []]

  def new do
    %Tempest.Topology{}
  end

  def add_processor(topology, module, concurrency \\ 1) do
    Map.update! topology, :processors, fn map ->
      Map.put map, module, %{ concurrency: concurrency, pids: [] }
    end
  end

  def add_link(topology, src_module, dst_module, type \\ :shuffle, options \\ []) do
    Map.update! topology, :links, fn list ->
      link = { src_module, dst_module, type, options }
      [ link | list ]
    end
  end

  def get_concurrency(topology, module) do
    topology.processors[module].concurrency
  end

  def get_outgoing_links(topology, module) do
    Enum.reduce topology.links, [], fn link, memo ->
      { src_module, dst_module, _, _ } = link
      if src_module == module do
        [ link | memo ]
      else
        memo
      end
    end
  end

  def get_incoming_links(topology, module) do
    Enum.reduce topology.links, [], fn link, memo ->
      { src_module, dst_module, _, _ } = link
      if dst_module == module do
        [ link | memo ]
      else
        memo
      end
    end
  end

  def get_outgoing_modules(topology, module) do
    topology
    |> get_outgoing_links(module)
    |> Enum.map(fn { _, mod, _, _ } -> mod end)
  end

  def get_incoming_modules(topology, module) do
    topology
    |> get_incoming_links(module)
    |> Enum.map(fn { mod, _, _, _ } -> mod end)
  end

  def get_outgoing_pids(topology, module) do
    topology
    |> get_outgoing_modules(module)
    |> Enum.flat_map( &(topology.processors[&1].pids) )
  end

  def get_incoming_pids(topology, module) do
    topology
    |> get_incoming_modules(module)
    |> Enum.flat_map( &(topology.processors[&1].pids) )
  end

  def start(topology) do
    processors = Enum.reduce topology.processors, %{}, fn { module, settings }, memo ->
      pids = Enum.map 1..settings.concurrency, fn _ ->
        { :ok, pid } = GenServer.start_link(module, %{})
        pid
      end
      Map.put(memo, module, Map.put(settings, :pids, pids))
    end

    topology = Map.put(topology, :processors, processors)

    Enum.each processors, fn { module, settings } ->
      Enum.each settings.pids, fn pid ->
        GenServer.call(pid, { :set_topo, topology })
      end
    end

    topology
  end

  def emit(topology, module, message) do
    %{ pids: pids, concurrency: concurrency } = topology.processors[module]
    n = :rand.uniform(concurrency) - 1
    pid = Enum.at(pids, n)
    GenServer.cast(pid, { :ingest, message })

    topology
  end

  def finish(topology) do

    # Figure out all processors that do not have incoming links.
    processors = Enum.filter topology.processors, fn { module, _ } ->
      get_incoming_links(topology, module) == []
    end

    # Now iterate over all of them, sending the done message to their pids.
    Enum.each processors, fn { module, processor } ->
      Enum.each processor.pids, fn pid ->
        GenServer.call(pid, :done, :infinity)
      end
    end

    topology
  end

end
