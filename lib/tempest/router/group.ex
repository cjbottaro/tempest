defmodule Tempest.Router.Group do
  use Tempest.Router

  field :fn

  def route %{ pids: pids, count: count, fn: f }, message do
    routing_key = if f do
      f.(message)
    else
      message
    end

    n = :crypto.hash(:md5, routing_key) |> :binary.decode_unsigned

    pids[ rem(n, count) ]
  end
end
