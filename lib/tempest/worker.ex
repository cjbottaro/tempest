defmodule Tempest.Worker do
  use GenServer

  alias Tempest.Topology

  def handle_call :inspect, _from, state do
    { :reply, state, state }
  end

  def handle_call { :start, {name, topology} }, _from, state do
    processor = topology.processors[name]

    routers = topology
      |> Topology.outgoing_links(name)
      |> Enum.map( &(topology.processors[&1].router) )

    context = %{
      routers: routers,
      state: processor.initial_state,
      options: processor
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
      context: context,
      stats: %{
        start_at: :os.system_time(:milli_seconds),
        time_til_first_message: nil,
        count: 0,
        time: 0,
        done_at: nil,
        done_time: nil,
        last_message_at: nil,
        wait_time: 0
      }
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

    state = if received_done_from == incoming_pids || incoming_pids == nil do
      t1 = :os.system_time(:milli_seconds)
      module.done(context)
      t2 = :os.system_time(:milli_seconds)
      Enum.each outgoing_pids, &( GenServer.call(&1, :done, :infinity) )

      stats = %{ state.stats | done_at: t1, done_time: t2 - t1 }
      %{ state | stats: stats }
    else
      state
    end

    { :reply, :ok, %{ state | received_done_from: received_done_from } }
  end

  def handle_call :stats, _from, state do
    { :reply, state.stats, state }
  end

  def handle_cast { :message, message }, state do
    %{
      module: module,
      context: context,
      stats: stats
    } = state

    stats = if stats.last_message_at do
      wait_time = :os.system_time(:milli_seconds) - stats.last_message_at
      %{ stats | wait_time: stats.wait_time + wait_time }
    else
      stats
    end

    stats = if !stats.time_til_first_message do
      t = :os.system_time(:milli_seconds)
      %{ stats | time_til_first_message: t - state.stats.start_at }
    else
      stats
    end

    t1 = :os.system_time(:milli_seconds)
    result = module.process(context, message)
    t2 = :os.system_time(:milli_seconds)
    time = stats.time + (t2 - t1)
    count = stats.count + 1

    stats = %{ stats | count: count, time: time }

    state = case result do
      { :update_state, new_state } ->
        put_in(state.context.state, new_state)
      _ ->
        state
    end

    # if :random.uniform < 0.0001 do
    #   throughput = state.stats.count / (state.stats.time / 1000)
    #   elapse_time = :os.system_time(:milli_seconds) - state.stats.start_at
    #   real_throughput = state.stats.count / (elapse_time / 1000)
    #   IO.puts "#{state.name} #{state.module}\n#{throughput} msg/s\n#{real_throughput} msg/s\n#{inspect state.stats}\n"
    # end

    stats = %{ stats | last_message_at: :os.system_time(:milli_seconds) }

    state = %{ state | stats: stats }

    { :noreply, state }
  end

  defp update_stat(state, :set, key, value) do
    %{ state | stats: Map.put(state.stats, key, value) }
  end

  defp update_stat(state, :add, key, value) do
    %{ state | stats: Map.update!(state.stats, key, &(&1+value)) }
  end

end
