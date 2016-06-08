defmodule Tempest.Stats do
  import ExPrintf, only: [printf: 2]
  import Tempest.Worker.Stats

  def get(topology) do
    Enum.map topology.components, fn {name, component} ->
      {name, component.processor, calc_component_stats(component)}
    end
  end

  def pretty_print(stats) do
    Enum.each stats, fn {name, processor, pid_stats} ->
      IO.puts "#{name} (#{display_processor processor})"
      Enum.each pid_stats, fn {pid, stats} ->
        IO.puts "  #{inspect pid}"
        printf("    message count     : %d\n", [message_count(stats)])
        printf("    real time         : %.5f\n", [real_time(stats)/1_000_000])
        printf("    code time         : %.5f\n", [code_time(stats)/1_000_000])
        printf("    wait time         : %.5f\n", [wait_time(stats)/1_000_000])
        printf("    wait time (first) : %.5f\n", [wait_time_first(stats)/1_000_000])
        printf("    done time         : %.5f\n", [done_time(stats)/1_000_000])
        printf("    real throughput   : %.5f\n", [real_throughput(stats)])
        printf("    code throughput   : %.5f\n", [code_throughput(stats)])
      end
    end
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

end
