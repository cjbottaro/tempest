defmodule Tempest.Processor do

  defmacro __using__(_) do
    quote do
      def initial_state do
        nil
      end

      def process(context, message) do
      end

      def done(context) do
      end

      defoverridable [initial_state: 0, process: 2, done: 1]

      import Tempest.Processor, only: [emit: 2, get_state: 1, update_state: 2]
    end
  end

  defstruct [
    name: nil,
    module: nil,
    concurrency: 1,
    pids: %{},
    router: nil,
    options: %{},
    initial_state: nil
  ]

  @main_keys [:name, :module, :concurrency]
  @invalid_keys [:pids, :options, :initial_state]

  def new(attributes \\ []) do
    attributes = Enum.into(attributes, %{})
    processor = %__MODULE__{}

    Enum.each attributes, fn {key, value} ->
      if Enum.member?(@invalid_keys, key) do
        raise ArgumentError, "#{inspect key} is not a valid option"
      end
    end

    filter = fn {key, _} -> Enum.member?(@main_keys, key) end
    main_attributes = Enum.filter(attributes, filter) |> Enum.into(%{})
    processor = Map.merge(processor, main_attributes)

    non_option_keys = @main_keys ++ @invalid_keys
    filter = fn {key, _} -> !Enum.member?(non_option_keys, key) end
    options = Enum.filter(attributes, filter) |> Enum.into(%{})
    processor = %{ processor | options: options }

    %{ processor | initial_state: processor.module.initial_state }
  end

  def emit(context, message) do
    Enum.each context.routers, fn router ->
      case router.__struct__.route(router, message) do
        pid -> GenServer.cast(pid, { :message, message })
      end
    end
  end

  def get_state(context) do
    context.state
  end

  def update_state(context, f) do
    { :update_state, f.(context.state) }
  end

end
