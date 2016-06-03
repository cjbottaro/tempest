defmodule Tempest.Router.Random do
  defstruct [:pids, :count]

  def route(router, _) do
    # This optimization helps significantly...
    # I guess generating random numbers is expensive.
    if router.count == 1 do
      router.pids[0]
    else
      n = :random.uniform(router.count) - 1
      router.pids[n]
    end
  end
end
