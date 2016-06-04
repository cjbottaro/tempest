# This is literally an order of magnitude slower than Router.Random,
# due to the use of an Agent. It's done that way to make the API pretty.
defmodule Tempest.Router.Shuffle do
  use Tempest.Router

  field :agent_pid

  def after_init(router) do
    { :ok, pid } = Agent.start_link(fn -> 0 end)
    Map.put router, :agent_pid, pid
  end

  def route(router, _) do
    %{ pids: pids, count: count } = router
    index = increment(router)
    pids[ rem(index, count) ]
  end

  defp increment %{ agent_pid: agent_pid } do
    Agent.get_and_update agent_pid, &( {&1, &1 + 1} )
  end

end
