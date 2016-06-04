alias Tempest.{Topology, Processor}
alias DistributedJoin.FileReader

router = Tempest.Router.Group.new fn: fn message ->
  case message do
    { "User", id, _, } -> id
    { "Post", _, user_id, _ } -> user_id
  end
end

equi_join_processor = Processor.EquiJoin.new concurrency: 4, router: router, joining_fn: fn message ->
  case message do
    { "User", id, _, } -> { :left, id }
    { "Post", _, user_id, _ } -> { :right, user_id }
    _ -> nil
  end
end

topology = Topology.new
  |> Topology.add_processor(:reader, FileReader, concurrency: 2, router: :shuffle)
  |> Topology.add_processor(:joiner, equi_join_processor)
  |> Topology.add_link(:reader, :joiner)
  |> Topology.start
  |> Topology.emit(:reader, "../data_gen/users.csv")
  |> Topology.emit(:reader, "../data_gen/posts.csv")
  |> Topology.stop
