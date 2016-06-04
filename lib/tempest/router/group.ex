defmodule Tempest.Router.Group do
  use Tempest.Router

  field :fn

  def route %{ pids: pids, count: count, fn: f }, message do
    routing_key = if f do
      f.(message)
    else
      message
    end

    n = cond do
      is_integer(routing_key) ->
        routing_key
      is_binary(routing_key) ->
        :binary.decode_unsigned(routing_key)
    end

    pids[ rem(n, count) ]
  end
end
