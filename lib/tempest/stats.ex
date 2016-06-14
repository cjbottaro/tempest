defmodule Tempest.Stats do
  import ExPrintf, only: [printf: 2]
  import Tempest.Worker.Stats

  defstruct [:worker_stats, :summerized_stats]

  def get(topology) do
    stats = Enum.map topology.components, fn {name, component} ->
      {name, component.processor, calc_component_stats(component)}
    end
    %__MODULE__{ worker_stats: stats }
  end

  def summerize(stats) do
    summerized_stats = Enum.map stats.worker_stats, fn {name, processor, worker_stats} ->
      summerized_stats = %{
        message_count:    sum(worker_stats, :message_count),
        emit_count:       sum(worker_stats, :emit_count),
        start_at:         avg(worker_stats, :start_at),
        first_message_at: avg(worker_stats, :first_message_at),
        done_received_at: avg(worker_stats, :done_received_at),
        done_at:          avg(worker_stats, :done_received_at),
        user_time:        sum(worker_stats, :user_time),
        idle_time:        sum(worker_stats, :idle_time)
      }
      {name, processor, summerized_stats}
    end
    %{ stats | summerized_stats: summerized_stats }
  end

  def pretty_print(stats) do
    %{ worker_stats: worker_stats, summerized_stats: summerized_stats } = stats
    if summerized_stats do
      Enum.each summerized_stats, fn {name, processor, summerized_stats} ->
        IO.puts "#{inspect name} (#{display_processor processor})"
        pretty_print_worker_stats(summerized_stats, "  ")
      end
    else
      Enum.each worker_stats, fn {name, processor, pid_stats} ->
        IO.puts "#{inspect name} (#{display_processor processor})"
        Enum.each pid_stats, fn {pid, stats} ->
          IO.puts "  #{inspect pid}"
          pretty_print_worker_stats(stats, "    ")
        end
      end
    end
  end

  defp pretty_print_worker_stats(stats, padding) do
    printf("%smessage count     : %d\n",   [padding, message_count(stats)])
    printf("%semit count        : %d\n",   [padding, emit_count(stats)])
    printf("%sreal time         : %.5f\n", [padding, real_time(stats)/1_000_000])
    printf("%suser time         : %.5f\n", [padding, user_time(stats)/1_000_000])
    printf("%sidle time         : %.5f\n", [padding, idle_time(stats)/1_000_000])
    printf("%swait time         : %.5f\n", [padding, wait_time(stats)/1_000_000])
    printf("%sdone time         : %.5f\n", [padding, done_time(stats)/1_000_000])
    printf("%sreal throughput   : %.5f\n", [padding, real_throughput(stats)])
    printf("%suser throughput   : %.5f\n", [padding, user_throughput(stats)])
    printf("%semit throughput   : %.5f\n", [padding, emit_throughput(stats)])
  end

  defp calc_component_stats(component) do
    Enum.reduce component.worker_pids, %{}, fn pid, memo ->
      Map.put memo, pid, GenServer.call(pid, :stats)
    end
  end

  defp display_processor(processor) do
    list = processor.__struct__
      |> Atom.to_string
      |> String.split(".")
    [ _ | rest ] = list
    Enum.join(rest, ".")
  end

  defp avg(worker_stats, field) do
    sum(worker_stats, field) / Map.size(worker_stats)
  end

  defp sum(worker_stats, field) do
    Enum.reduce worker_stats, 0, fn {_, stats}, memo ->
      memo + Map.get(stats, field)
    end
  end

end
