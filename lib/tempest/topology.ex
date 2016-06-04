defmodule Tempest.Topology do
  defstruct [processors: %{}, links: []]

  def new do
    %Tempest.Topology{}
  end

  def add_processor(topology, name, processor) when is_map(processor) do
    if Map.has_key?(topology.processors, name) do
      raise ArgumentError, "#{inspect name} already defined"
    end
    processor = %{ processor | name: name }
    processors = Map.put topology.processors, name, processor
    %{ topology | processors: processors }
  end

  def add_processor(topology, name, module, options \\ []) when is_atom(module) do
    processor = module.new(options)
    add_processor(topology, name, processor)
  end

  def add_link(topology, src, dst) do
    Map.update! topology, :links, &( [{src, dst} | &1] )
  end

  def incoming_links(topology, name) do
    Enum.reduce topology.links, [], fn {src, dst}, memo ->
      if dst == name do
        [ src | memo ]
      else
        memo
      end
    end
  end

  def outgoing_links(topology, name) do
    Enum.reduce topology.links, [], fn {src, dst}, memo ->
      if src == name do
        [ dst | memo ]
      else
        memo
      end
    end
  end

  def start(topology) do
    Enum.each topology.processors, fn {name, processor} ->
      Enum.each processor.pids, fn {_, pid} ->
        GenServer.call(pid, { :start, {name, topology} })
      end
    end

    topology
  end

  def emit(topology, name, message) do
    alias Tempest.Router
    router = topology.processors[name].router
    pid = Router.route(router, message)
    GenServer.cast pid, { :message, message }
    topology
  end

  def stop(topology) do
    Enum.each topology.processors, fn {name, processor} ->
      if incoming_links(topology, name) == [] do
        Enum.each(processor.pids, &( GenServer.call(elem(&1, 1), :done, :infinity) ))
      end
    end
  end

end
