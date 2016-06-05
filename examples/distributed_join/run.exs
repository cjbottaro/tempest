alias Tempest.{Topology, Processor, Stats}
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
  |> Topology.add_processor(:reader, FileReader, concurrency: 5, router: :shuffle)
  |> Topology.add_processor(:joiner, equi_join_processor)
  |> Topology.add_link(:reader, :joiner)

  |> Topology.start
  |> Topology.emit(:reader, "../data_gen/users.csv")
  |> Topology.emit(:reader, "../data_gen/posts_small_1.csv")
  |> Topology.emit(:reader, "../data_gen/posts_small_2.csv")
  |> Topology.emit(:reader, "../data_gen/posts_small_3.csv")
  |> Topology.emit(:reader, "../data_gen/posts_small_4.csv")
  |> Topology.emit(:reader, "../data_gen/posts_small_5.csv")
  |> Topology.emit(:reader, "../data_gen/posts_small_6.csv")
  |> Topology.emit(:reader, "../data_gen/posts_small_7.csv")
  |> Topology.emit(:reader, "../data_gen/posts_small_8.csv")
  |> Topology.emit(:reader, "../data_gen/posts_small_9.csv")
  |> Topology.emit(:reader, "../data_gen/posts_small_10.csv")
  |> Topology.stop

  |> Stats.get
  |> Stats.pretty_print
