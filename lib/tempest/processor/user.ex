defmodule Tempest.Processor.User do
  use Tempest.Processor

  alias Tempest.Repo
  alias Tempest.User
  alias Tempest.Application

  def process(topo, state, %Application{} = application) do
    #IO.puts "User #{inspect self} received #{application.id}"
    case Map.fetch(state, application.user_id) do
      { :ok, user } ->
        emit(topo, user)
        state
      :error ->
        user = memcache_fetch("User:#{application.user_id}", fn _ -> Repo.get(User, application.user_id) end)
        emit(topo, user)
        Map.put(state, user.id, user)
    end
  end

  def memcache_fetch(key, func) do
    case Memcache.Client.get(key) do
      %{ status: :ok, value: value } -> value
      %{ status: :key_not_found } ->
        value = func.(key)
        Memcache.Client.set(key, value)
        value
    end
  end

end
