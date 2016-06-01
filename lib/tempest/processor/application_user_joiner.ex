defmodule Tempest.Processor.ApplicationUserJoiner do
  use Tempest.Processor

  alias Tempest.{Application, User}

  def initial_state do
    %{ applications: [], users: %{} }
  end

  def process(topo, state, %Application{} = application) do
    Map.update! state, :applications, &( [application | &1] )
  end

  def process(topo, state, %User{} = user) do
    Map.update! state, :users, &Map.put_new(&1, user.id, user)
  end

  def done(topo, state) do
    Enum.each state.applications, fn application ->
      user = state.users[application.user_id]
      emit(topo, Map.put(application, :user, user))
    end
  end

end
