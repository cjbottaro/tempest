defmodule UserEmitter do
  use Tempest.Processor

  alias Tempest.{Repo, User}

  def process(topo, state, %{ user_id: id }) do
    case Map.fetch(state, id) do
      { :ok, user } ->
        emit(topo, user)
        state
      :error ->
        user = memcache_fetch("tempest:User:#{id}", fn _ -> Repo.get(User, id) end)
        emit(topo, user)
        Map.put(state, id, user)
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
