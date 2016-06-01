defmodule CategoryEmitter do
  use Tempest.Processor

  alias Tempest.{Repo, Category}

  def process(topo, state, %{ category_id: id }) do
    case Map.fetch(state, id) do
      { :ok, category } ->
        emit(topo, category)
        state
      :error ->
        category = memcache_fetch("tempest:Category:#{id}", fn _ -> Repo.get(Category, id) end)
        emit(topo, category)
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
