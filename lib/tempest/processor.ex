defmodule Tempest.Processor do

  defmacro __using__(_) do
    quote do

      # No initial state by default.
      @initial_state nil

      # Have to register options this way so it accumulates.
      Module.register_attribute __MODULE__, :options, accumulate: true

      # So we can do stuff with the attributes.
      @before_compile Tempest.Processor

      def done(context) do
      end

      defoverridable [done: 1]

      import Tempest.Processor, only: [
        emit: 2,
        option: 1,
        option: 2,
        initial_state: 1,
        get_state: 1,
        update_state: 2
      ]

      option :concurrency,    required: true,  default: 1
    end
  end

  defmacro option(name, options \\ []) do
    check_option_name!(name)
    check_option_options!(options)

    quote bind_quoted: [name: name, options: options] do
      @options { name, options }
    end
  end

  defp check_option_name!(name) do
    if !is_atom(name) do
      raise ArgumentError, "option name must be atom, got #{inspect name}"
    end
  end

  @valid_option_options ~w(required default)

  defp check_option_options!(options) do
    Enum.each options, fn {k, v} ->
      if Enum.member?(@valid_option_options, k) do
        raise ArgumentError, "#{inspect k} is not a valid option"
      end
    end
  end

  defmacro initial_state(state) do
    quote do
      @initial_state unquote(state)
    end
  end

  defmacro __before_compile__(_env) do
    quote do

      [
        name: nil,
        initial_state: @initial_state,
        pids: nil,
        router: nil
      ]
      ++ Enum.map(@options, fn {name, opts} -> { name, opts[:default] } end)
      |> defstruct

      # Just delegate to a normal function Tempest.Processor
      def new(name, options \\ []) do
        Tempest.Processor.new(name, __MODULE__, @options, Enum.into(options, %{}))
      end

    end
  end

  def new(name, module, option_specs, option_values) do
    alias Tempest.Router

    if !is_binary(name) && !is_atom(name) do
      raise ArgumentError, "name must be string or atom, got: #{inspect name}"
    end

    router_options = option_values[:routing]
    option_values = Map.delete(option_values, :routing)

    processor = module.__struct__
      |> Map.merge(option_values)
      |> Map.put(:name, name)

    pids = Enum.map(1..processor.concurrency, fn i ->
      { :ok, pid } = GenServer.start_link(Tempest.Worker, name)
      { i - 1, pid }
    end) |> Enum.into(%{})

    router = Router.new(router_options, pids)

    Map.merge processor, %{ pids: pids, router: router }
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
