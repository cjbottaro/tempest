defmodule Tempest.Stats do
  import Float, only: [round: 2]

  def get(topology) do
    Enum.reduce topology.processors, %{}, fn {name, processor}, memo ->
      stats = Enum.reduce processor.pids, %{}, fn {_, pid}, memo ->
        stats = GenServer.call(pid, :stats)
        calculated_stats = %{
          messages: messages(stats),
          elapse_time: elapse_time(stats),
          code_time: code_time(stats),
          wait_time: wait_time(stats),
          code_throughput: code_throughput(stats),
          real_throughput: real_throughput(stats),
        }
        Map.put(memo, pid, calculated_stats)
      end
      Map.put(memo, name, %{module: processor.__struct__, pid_stats: stats})
    end
  end

  def pretty_print(stats) do
    Enum.each stats, fn { name, stats } ->
      %{ module: module, pid_stats: pid_stats } = stats
      IO.puts "#{name}: #{module}"
      Enum.each pid_stats, fn {pid, stats} ->
        IO.puts "  #{inspect pid}"
        IO.puts "    messages        : #{stats.messages}"
        IO.puts "    elapse_time     : #{stats.elapse_time}"
        IO.puts "    code_time       : #{stats.code_time}"
        IO.puts "    wait_time       : #{stats.wait_time}"
        IO.puts "    code_throughput : #{stats.code_throughput}"
        IO.puts "    real_throughput : #{stats.real_throughput}"
      end
    end
  end

  defp messages(stats) do
    stats.count
  end

  defp elapse_time(stats) do
    (stats.done_at - stats.start_at) / 1000
      |> round(2)
  end

  defp code_time(stats) do
    stats.time / 1000
      |> round(2)
  end

  defp wait_time(stats) do
    stats.wait_time / 1000
  end

  defp code_throughput(stats) do
    code_time = code_time(stats)
    if code_time == 0 do
      :infinity
    else
      round(stats.count / code_time, 2)
    end
  end

  defp real_throughput(stats) do
    stats.count / elapse_time(stats)
      |> round(2)
  end

end
