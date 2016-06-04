# This is literally an order of magnitude slower than Router.Random,
# due to the use of an Agent. It's done that way to make the API pretty.
defmodule Tempest.Router.Shuffle do

  # This will take precedence over the defstruct call from `use Tempest.Router`.
  # It's needed because if you add "extra" keys to a struct, then `inspect`
  # won't display them as structs anymore.
  defstruct [:pids, :count, :index_pid]

  use Tempest.Router

  def new(pids) do
    { :ok, pid } = Agent.start_link(fn -> 0 end)
    Map.put super(pids), :index_pid, pid
  end

  def route(router, _) do
    %{ pids: pids, count: count } = router
    index = increment(router)
    pids[ rem(index, count) ]
  end

  defp increment %{ index_pid: index_pid } do
    Agent.get_and_update index_pid, &( {&1, &1 + 1} )
  end

end
