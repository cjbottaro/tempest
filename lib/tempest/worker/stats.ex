defmodule Tempest.Worker.Stats do
  defstruct [
    message_count:        0,
    emit_count:           0,
    emit_count_ets:       nil,
    start_at:             nil,
    first_message_at:     nil,
    previous_message_at:  nil,
    done_received_at:     nil,
    done_at:              nil,
    user_time:            0,
    idle_time:            0
  ]

  def message_count(stats) do
    stats.message_count
  end

  def emit_count(stats) do
    stats.emit_count
  end

  def real_time(stats) do
    stats.done_received_at - stats.first_message_at
  end

  def user_time(stats) do
    stats.user_time
  end

  def done_time(stats) do
    stats.done_at - stats.done_received_at
  end

  def idle_time(stats) do
    stats.idle_time - wait_time(stats)
  end

  def wait_time(stats) do
    stats.first_message_at - stats.start_at
  end

  def real_throughput(stats) do
    message_count(stats) / (real_time(stats) / 1_000_000)
  end

  def user_throughput(stats) do
    message_count(stats) / (user_time(stats) / 1_000_000)
  end

  def emit_throughput(stats) do
    emit_count(stats) / (user_time(stats) / 1_000_000)
  end

end
