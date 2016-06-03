defmodule Tempest.Router.Group do
  defstruct [:pids, :count, :type, :arg]

  def new(attributes \\ []) do
    pids  = attributes[:pids]
    count = attributes[:count]
    type  = attributes[:type] || :identity
    arg   = attributes[:arg]
    %__MODULE__{ pids: pids, count: count, type: type, arg: arg }
  end

  def route(router, message) do
    n = case router.type do
      :identity ->
        :binary.decode_unsigned(message)
    end

    router.pids[ rem(n, router.count) ]
  end
end
