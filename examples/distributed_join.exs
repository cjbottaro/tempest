alias Tempest.{Topology, Router, Stats}
alias Tempest.ProcessorLib.{FileReader, Function, EquiJoin}

size = Enum.at(System.argv, 0) || "big"

line_processor = fn line ->
  line |> String.split(",") |> List.to_tuple
end

router = Router.Group.new fn: fn message ->
  case message do
    { "User", id, _, } -> id
    { "Post", _, user_id, _ } -> user_id
  end
end

joiner = EquiJoin.new join_fn: fn message ->
  case message do
    { "User", id, _, } -> { :left, id }
    { "Post", _, user_id, _ } -> { :right, user_id }
  end
end

Topology.new
  |> Topology.add_processor(:reader, FileReader, concurrency: 2, router: Router.Shuffle)
  |> Topology.add_processor(:tuplizer, Function, concurrency: 2, fn: line_processor)
  |> Topology.add_processor(:joiner, joiner, concurrency: 4, router: router)

  |> Topology.add_link(:reader, :tuplizer)
  |> Topology.add_link(:tuplizer, :joiner)

  |> Topology.begin_computation
  |> Topology.emit(:reader, "examples/data/users_#{size}.csv")
  |> Topology.emit(:reader, "examples/data/posts_#{size}.csv")
  |> Topology.end_computation

  |> Stats.get
  |> Stats.pretty_print
