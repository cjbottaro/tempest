defmodule Tempest.Worker.Stats do
  defstruct [
    message_count:        0,
    start_at:             nil,
    first_message_at:     nil,
    previous_message_at:  nil,
    done_received_at:     nil,
    done_at:              nil,
    code_time:            0,
    wait_time:            0
  ]

  def message_count(stats) do
    stats.message_count
  end

  def real_time(stats) do
    stats.done_received_at - stats.first_message_at
  end

  def code_time(stats) do
    stats.code_time
  end

  def done_time(stats) do
    stats.done_at - stats.done_received_at
  end

  def wait_time(stats) do
    stats.wait_time - wait_time_first(stats)
  end

  def wait_time_first(stats) do
    stats.first_message_at - stats.start_at
  end

  def real_throughput(stats) do
    message_count(stats) / (real_time(stats) / 1_000_000)
  end

  def code_throughput(stats) do
    message_count(stats) / (code_time(stats) / 1_000_000)
  end

end
