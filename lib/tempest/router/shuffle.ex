# This is literally an order of magnitude slower than Router.Random,
# due to the use of an Agent. It's done that way to make the API pretty.
defmodule Tempest.Router.Shuffle do
  defstruct [pids: nil, count: nil, index_pid: nil]

  def new(attributes \\ []) do
    { :ok, pid } = Agent.start_link(fn -> 0 end)

    attributes = attributes
      |> Enum.into(%{})
      |> Map.put(:index_pid, pid)

    Map.merge(%__MODULE__{}, attributes)
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
