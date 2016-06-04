defmodule Tempest.Router do
  alias Tempest.Router

  defmacro __using__(_) do
    quote do
      Module.register_attribute __MODULE__, :fields, accumulate: true

      import Router, only: [field: 1, field: 2]

      field :pids
      field :count

      def after_init(router) do
        router
      end

      defoverridable [after_init: 1]

      @before_compile Router
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defstruct @fields

      def new(attributes \\ []) do
        Router.new(__MODULE__, attributes)
      end
    end
  end

  defmacro field(name, default \\ nil) do
    validate_name!(name)
    quote bind_quoted: [name: name, default: default] do
      @fields { name, default }
    end
  end

  defp validate_name!(name) do
    if !is_atom(name) do
      raise ArgumentError, "field names must be atoms, got: #{inspect name}"
    end
  end

  def new(module, attributes) do
    attributes = Map.new(attributes)
    module.__struct__ |> Map.merge(attributes) |> module.after_init
  end

  def set_pids(router, pids) when is_map(pids) do
    %{ router | pids: pids, count: Map.size(pids) }
  end

  def set_pids(router, pids) when is_list(pids) do
    pids = Enum.with_index(pids)
      |> Enum.map(fn {pid, i} -> {i, pid} end)
      |> Map.new
    set_pids(router, pids)
  end

  def from_options %{ __struct__: _ } = router do
    router
  end

  def from_options(nil) do
    Router.Random.new
  end

  def from_options(:random) do
    Router.Random.new
  end

  def from_options(:shuffle) do
    Router.Shuffle.new
  end

  def from_options(:group) do
    Router.Group.new
  end

  def from_options {:group, options} do
    Router.Group.new(options)
  end

  def route(router, message) do
    # Is this gross? Am I too OO? Would I be shunned?
    router.__struct__.route(router, message)
  end

end
