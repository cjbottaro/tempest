defmodule Tempest.Topology do
  alias Tempest.Topology.Component

  defstruct [components: %{}, links: []]

  def new do
    %Tempest.Topology{}
  end

  @user_facing_options %{
    concurrency: 1,
    router: :random
  }

  def add_processor(topology, name, module_or_struct, options \\ []) do

    # Make sure the name is an atom or string.
    if !is_atom(name) && !is_binary(name) do
      raise ArgumentError, "name must be atom or string, got: #{inspect name}"
    end

    # Make sure we don't already have this name in the topology.
    if Map.has_key?(topology.components, name) do
      raise ArgumentError, "#{inspect name} already defined"
    end

    # Separate the processor_option from add_processor options.
    {options, processor_options} = Enum.partition options, fn {k, _} ->
      Map.has_key?(@user_facing_options, k)
    end

    # Maybe build the processor.
    processor = cond do
      is_atom(module_or_struct) ->
        module_or_struct.new(processor_options)
      is_map(module_or_struct) ->
        if processor_options != [] do
          raise ArgumentError, "cannot pass options to already built processor: #{inspect processor_options}"
        end
        module_or_struct
    end

    # Build the component.
    component = Map.new(options)
      |> Map.put(:processor, processor)
      |> Component.new

    # Update the topology.
    components = Map.put(topology.components, name, component)
    %{ topology | components: components }
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

  def begin_computation(topology, args \\ nil) do
    get_router = fn name ->
      topology.components[name].router
    end

    get_pids = fn name ->
      topology.components[name].worker_pids
    end

    Enum.each topology.components, fn {name, component} ->
      routers = outgoing_links(topology, name) |> Enum.map(get_router)
      incoming_pids = incoming_links(topology, name) |> Enum.flat_map(get_pids)
      config = %{ routers: routers, incoming_pids: incoming_pids }
      Enum.each component.worker_pids, fn pid ->
        GenServer.call pid, {:begin_computation, config, args}
      end
    end

    topology
  end

  def emit(topology, name, message) do
    alias Tempest.Router
    router = topology.components[name].router
    pid = Router.route(router, message)
    GenServer.cast pid, { :message, message }
    topology
  end

  def end_computation(topology) do
    Enum.each topology.components, fn {name, component} ->
      if incoming_links(topology, name) == [] do
        Enum.each(component.worker_pids, &( GenServer.call(&1, :end_computation, :infinity) ))
      end
    end
    topology
  end

end
