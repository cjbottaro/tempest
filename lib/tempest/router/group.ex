defmodule Tempest.Router.Group do
  defstruct [:pids, :count, :type, :arg]

  use Tempest.Router

  def route(router, message) do
    n = case router.type do
      :identity ->
        :binary.decode_unsigned(message)
    end

    router.pids[ rem(n, router.count) ]
  end
end
