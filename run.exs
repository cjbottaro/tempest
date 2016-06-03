# alias Tempest.Topology
# alias Tempest.Processor
#
# Tempest.Repo.start_link
#
# topology = Topology.new
#   |> Topology.add_processor(Processor.Application)
#   |> Topology.add_processor(Processor.User)
#   |> Topology.add_processor(Processor.ApplicationUserJoiner, 2)
#   |> Topology.add_link(Processor.Application, Processor.User)
#   |> Topology.add_link(Processor.Application, Processor.ApplicationUserJoiner, :group, field: :user_id)
#   |> Topology.add_link(Processor.User, Processor.ApplicationUserJoiner, :group, field: :id)
#   |> Topology.start
#
# pid = topology.processors[Processor.Application].pids |> Enum.at(0)
# Tempest.Repo.all(Tempest.Application) |> Enum.each(fn application ->
#   GenServer.cast(pid, { :ingest, application })
# end)
#
# GenServer.call(pid, :done)
# IO.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
# IO.puts "!!!!!!!!!!!!!!!!!! EXITING PROGRAM !!!!!!!!!!!!!!!!!!!!!"
# IO.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"


# { :ok, pid } = GenServer.start_link(Processor.Application, %{ topo: topology, state: %{} })
#
# Tempest.Repo.all(Tempest.Application) |> Enum.each(fn application ->
#   GenServer.cast(pid, application)
# end)

# Tempest.Repo.start_link
# { :ok, joiner_pid_0 } = GenServer.start_link(Tempest.Joiner, %{})
# { :ok, joiner_pid_1 } = GenServer.start_link(Tempest.Joiner, %{})
#
# Tempest.Repo.all(Tempest.Application) |> Enum.each(fn application ->
#   # user_id = application.user_id |> Integer.to_string
#   # i = :crypto.hash(:md5, user_id)
#   #   |> :binary.decode_unsigned
#   #   |> rem(2)
#   i = rem(application.user_id, 2)
#   if i == 0 do
#     GenServer.cast joiner_pid_0, { application, :user_id }
#   else
#     GenServer.cast joiner_pid_1, { application, :user_id }
#   end
# end)
# GenServer.call joiner_pid_0, { :done, Tempest.Application }
# GenServer.call joiner_pid_1, { :done, Tempest.Application }
#
#
# Tempest.Repo.all(Tempest.User) |> Enum.each(fn user ->
#   i = rem(user.id, 2)
#   if i == 0 do
#     GenServer.cast joiner_pid_0, { user, :id }
#   else
#     GenServer.cast joiner_pid_1, { user, :id }
#   end
# end)
# GenServer.call joiner_pid_0, { :done, Tempest.User }
# GenServer.call joiner_pid_1, { :done, Tempest.User }
#
# GenServer.stop(joiner_pid_0)
#
#
# { ApplicationProducer, ApplicationUserJoiner, :group, :user_id }
# { ApplicationProducer, ApplicationCategoryJoiner, :group, :category_id }
# { ApplicationProducer, ApplicationOpportunityJoiner, :group, :opportunity_id }
#
# { UserProducer, ApplicationUserJoiner, :group, :id }
# { ApplicationProducer, ApplicationCategoryJoiner, :group, :category_id }
