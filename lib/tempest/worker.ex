defmodule Tempest.Worker do
  use GenServer

  defstruct [
    :processor,
    :processor_state,
    :processor_options,
    :routers,
    :incoming_pids,
    :done_incoming_pids,
    :stats
  ]

  alias Tempest.{Processor, Worker}
  alias Worker.Stats

  def init(processor) do
    worker = %Worker{
      processor: processor.__struct__,                     # Eww
      processor_state: processor.__struct__.initial_state, # Eww
      processor_options: Processor.get_options(processor),
      done_incoming_pids: MapSet.new,
      stats: %Stats{}
    }
    { :ok, worker }
  end

  def handle_call :inspect, _from, state do
    { :reply, state, state }
  end

  def handle_call { :begin_computation, config, _args }, _from, worker do
    %{ incoming_pids: incoming_pids, routers: routers } = config
    %{ stats: stats } = worker

    incoming_pids = if incoming_pids == [] do
      nil
    else
      MapSet.new(incoming_pids)
    end

    stats = %{ stats | start_at: :os.system_time(:micro_seconds) }

    worker = %{ worker |
      incoming_pids: incoming_pids,
      routers: routers,
      stats: stats
    }

    { :reply, :ok, worker }
  end

  def handle_call :end_computation, { from_pid, _ }, worker do
    %{
      processor: processor,
      incoming_pids: incoming_pids,
      done_incoming_pids: done_incoming_pids,
      routers: routers,
      stats: stats
    } = worker

    done_incoming_pids = MapSet.put(done_incoming_pids, from_pid)

    stats = if incoming_pids == nil || done_incoming_pids == incoming_pids do
      done_received_at = :os.system_time(:micro_seconds)
      processor.done(worker)
      done_at = :os.system_time(:micro_seconds)

      Enum.each routers, fn router ->
        Enum.each router.pids, fn {_, pid} ->
          GenServer.call(pid, :end_computation, :infinity)
        end
      end

      %{ stats | done_received_at: done_received_at, done_at: done_at }
    else
      stats
    end

    worker = %{ worker | done_incoming_pids: done_incoming_pids, stats: stats }

    { :reply, :ok, worker }
  end

  def handle_call :stats, _from, worker do
    { :reply, worker.stats, worker }
  end

  def handle_cast { :message, message }, worker do
    %{
      processor: processor,
      processor_state: processor_state,
      stats: stats
    } = worker

    %{
      start_at: start_at,
      user_time: user_time,
      idle_time: idle_time,
      message_count: message_count,
      first_message_at: first_message_at,
      previous_message_at: previous_message_at
    } = stats

    {first_message_at, idle_time} = if first_message_at do
      idle_time = idle_time + :os.system_time(:micro_seconds) - previous_message_at
      {first_message_at, idle_time}
    else
      first_message_at = :os.system_time(:micro_seconds)
      idle_time = first_message_at - start_at
      {first_message_at, idle_time}
    end

    t1 = :os.system_time(:micro_seconds)
    processor_state =
      case processor.process(worker, message) do
        { :__tempest_update_state__, new_state } -> new_state
        _ -> processor_state
      end
    t2 = :os.system_time(:micro_seconds)

    user_time = user_time + t2 - t1
    message_count = message_count + 1

    stats = %{ stats |
      user_time: user_time,
      idle_time: idle_time,
      message_count: message_count,
      first_message_at: first_message_at,
      previous_message_at: :os.system_time(:micro_seconds)
    }

    { :noreply, %{ worker | processor_state: processor_state, stats: stats } }
  end

end
