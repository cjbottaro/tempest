defmodule Tempest.Topology do
  defstruct [processors: %{}, links: []]

  alias Tempest.Processor

  def new do
    %Tempest.Topology{}
  end

  def add_processor(topology, name, module, options \\ []) do
    options = Enum.into(options, %{})
    router_options = Map.get(options, :routing)
    options = Map.delete(options, :routing)

    cond do
      !is_binary(name) && !is_atom(name) ->
        raise ArgumentError, "#{inspect name} must be a string or atom"
      Map.has_key?(topology.processors, name) ->
        raise ArgumentError, "#{inspect name} already defined"
      true ->
        nil
    end

    attributes = Map.merge(options, %{ name: name, module: module })
    processor = Processor.new(attributes)

    pids = Enum.map(1..processor.concurrency, fn i ->
      { :ok, pid } = GenServer.start_link(Tempest.Worker, name)
      { i - 1, pid }
    end) |> Enum.into(%{})

    processor = %{ processor | pids: pids }

    alias Tempest.Router.{Random, Shuffle, Group}

    router = case router_options do
      nil ->
        %Random{ count: processor.concurrency, pids: processor.pids }
      :random ->
        %Random{ count: processor.concurrency, pids: processor.pids }
      :shuffle ->
        Shuffle.new(count: processor.concurrency, pids: processor.pids)
      :group ->
        Group.new(count: processor.concurrency, pids: processor.pids)
      { :group, type, arg } ->
        Group.new(count: processor.concurrency, pids: processor.pids, type: type, arg: arg)
    end

    processor = %{ processor | router: router }

    Map.update! topology, :processors, fn map ->
      Map.put(map, name, processor)
    end
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
    Enum.each topology.processors, fn { _, processor } ->
      Enum.each processor.pids, fn { _, pid } ->
        GenServer.call(pid, { :start, topology })
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
