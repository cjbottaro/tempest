alias Tempest.{Topology, Processor, Stats}
alias DistributedJoin.FileReader

[ size | _ ] = System.argv

router = Tempest.Router.Group.new fn: fn message ->
  case message do
    { "User", id, _, } -> id
    { "Post", _, user_id, _ } -> user_id
  end
end

equi_join_processor = Processor.EquiJoin.new concurrency: 4, router: router, join_fn: fn message ->
  case message do
    { "User", id, _, } -> { :left, id }
    { "Post", _, user_id, _ } -> { :right, user_id }
  end
end

topology = Topology.new
  |> Topology.add_processor(:reader, FileReader, concurrency: 2, router: :shuffle)
  |> Topology.add_processor(:joiner, equi_join_processor, concurrency: 4, router: router)
  |> Topology.add_link(:reader, :joiner)

  |> Topology.begin_computation
  |> Topology.emit(:reader, "../data_gen/users_#{size}.csv")
  |> Topology.emit(:reader, "../data_gen/posts_#{size}.csv")
  |> Topology.stop

  |> Stats.get
  |> Stats.pretty_print
