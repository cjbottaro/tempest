defmodule Tempest.Router.Group do
  use Tempest.Router

  field :fn

  def route %{ pids: pids, count: count, fn: f }, message do
    routing_key = if f do
      f.(message)
    else
      message
    end

    n = :erlang.phash2(routing_key, count)

    pids[n]
  end
end
