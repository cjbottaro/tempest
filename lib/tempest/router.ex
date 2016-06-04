defmodule Tempest.Router do
  alias Tempest.Router

  defmacro __using__(_) do
    quote do
      defstruct [:pids, :count]

      def new(pids, keys \\ []) do
        keys = keys
          |> Enum.into(%{})
          |> Map.merge( %{pids: pids, count: Map.size(pids)} )

        Map.merge %__MODULE__{}, keys
      end

      defoverridable [new: 1, new: 2]
    end
  end

  def new(nil, pids) do
    Router.Random.new(pids)
  end

  def new(:random, pids) do
    Router.Random.new(pids)
  end

  def new(:shuffle, pids) do
    Router.Shuffle.new(pids)
  end

  def new(:group, pids) do
    Router.Group.new(pids)
  end

  def new({:group, type, arg}, pids) do
    Router.Group.new(pids, type: type, arg: arg)
  end

  def route(router, message) do
    # Is this gross? Am I too OO? Would I be shunned?
    router.__struct__.route(router, message)
  end

end
