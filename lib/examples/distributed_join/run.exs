alias Tempest.Topology

user_emitter = AssociationEmitter.new(User, :user_id)


topology = Topology.new
  |> Topology.add_processor(ApplicationEmitter)
  |> Topology.add_processor(UserEmitter)
  |> Topology.add_processor(CategoryEmitter)
  |> Topology.add_processor(ApplicationUserJoiner)
  |> Topology.add_processor(ApplicationCategoryJoiner)

topology = topology
  |> Topology.add_link(ApplicationEmitter, UserEmitter)
  |> Topology.add_link(ApplicationEmitter, CategoryEmitter)

topology = topology
  |> Topology.add_link(ApplicationEmitter, ApplicationUserJoiner, :group, key: :user_id)
  |> Topology.add_link(UserEmitter, ApplicationUserJoiner, :group, key: :id)

topology = topology
  |> Topology.add_link(ApplicationUserJoiner, ApplicationCategoryJoiner, key: :category_id)
  |> Topology.add_link(CategoryEmitter, ApplicationCategoryJoiner, key: :id)

topology = topology
  |> Topology.start
  |> Topology.emit(ApplicationEmitter, :go)
  |> Topology.finish
