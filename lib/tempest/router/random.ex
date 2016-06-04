defmodule Tempest.Router.Random do
  use Tempest.Router

  # This optimization helps significantly.
  def route %{ count: 1, pids: pids } do
    pids[0]
  end

  def route %{ count: count, pids: pids } do
    pids[ :random.uniform(count) - 1 ]
  end
end
