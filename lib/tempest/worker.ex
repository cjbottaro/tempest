defmodule Tempest.Worker do
  use GenServer

  alias Tempest.Topology

  def init(name) do
    { :ok, %{ name: name } }
  end

  def handle_call :inspect, _from, state do
    { :reply, state, state }
  end

  def handle_call { :start, topology }, _from, state do
    %{ name: name } = state

    processor = topology.processors[name]

    routers = topology
      |> Topology.outgoing_links(name)
      |> Enum.map( &(topology.processors[&1].router) )

    context = %{
      routers: routers,
      state: processor.initial_state
    }

    incoming_pids = topology
      |> Topology.incoming_links(name)
      |> Enum.flat_map( &(Map.values(topology.processors[&1].pids)) )

    incoming_pids = if incoming_pids == [] do
      nil
    else
      Enum.into(incoming_pids, MapSet.new)
    end

    outgoing_pids = topology
      |> Topology.outgoing_links(name)
      |> Enum.flat_map( &(Map.values(topology.processors[&1].pids)) )
      |> Enum.into(MapSet.new)

    state = %{
      name: name,
      module: processor.__struct__,
      incoming_pids: incoming_pids,
      outgoing_pids: outgoing_pids,
      received_done_from: MapSet.new,
      context: context
    }

    { :reply, :ok, state }
  end

  def handle_call :done, { from_pid, _ }, state do
    %{
      incoming_pids: incoming_pids,
      outgoing_pids: outgoing_pids,
      received_done_from: received_done_from,
      module: module,
      context: context
    } = state

    received_done_from = MapSet.put(received_done_from, from_pid)

    if received_done_from == incoming_pids || incoming_pids == nil do
      module.done(context)
      Enum.each outgoing_pids, &( GenServer.call(&1, :done, :infinity) )
    end

    { :reply, :ok, %{ state | received_done_from: received_done_from } }
  end

  def handle_cast { :message, message }, state do
    %{
      module: module,
      context: context
    } = state

    state = case module.process(context, message) do
      { :update_state, new_state } ->
        put_in(state.context.state, new_state)
      _ ->
        state
    end

    { :noreply, state }
  end

end
