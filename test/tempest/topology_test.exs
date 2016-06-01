defmodule Tempest.TopologyTest do
  use ExUnit.Case
  doctest Tempest

  import Tempest.Topology

  test "building a topology" do
    topology = new
      |> add_processor(Application)
      |> add_processor(User)
      |> add_processor(Joiner, 2)
      |> add_link(Application, User)
      |> add_link(Application, Joiner, :group, field: :user_id)
      |> add_link(User, Joiner, :group, field: :id)

    assert get_concurrency(topology, Application) == 1
    assert get_concurrency(topology, User) == 1
    assert get_concurrency(topology, Joiner) == 2

    assert get_outgoing_modules(topology, Application) == [User, Joiner]
    assert get_outgoing_modules(topology, User) == [Joiner]
    assert get_outgoing_modules(topology, Joiner) == []

    assert get_incoming_modules(topology, Application) == []
    assert get_incoming_modules(topology, User) == [Application]
    assert get_incoming_modules(topology, Joiner) == [Application, User]
  end
end
