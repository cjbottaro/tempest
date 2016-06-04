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
        get_options: 1,
        initial_state: 1,
        get_state: 1,
        update_state: 2
      ]

      option :concurrency, required: true,  default: 1
      option :router,      required: true,  default: :random
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
    Enum.each options, fn {k, _} ->
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
      def new(options \\ []) do
        Tempest.Processor.new(__MODULE__, @options, Enum.into(options, %{}))
      end

    end
  end

  def new(module, option_specs, options) do
    validate_options!(option_specs, options)

    {router, options} = Map.pop(options, :router)

    module.__struct__
      |> Map.merge(options)
      |> start_workers
      |> set_router(router)
  end

  def emit(context, message) do
    Enum.each context.routers, fn router ->
      case router.__struct__.route(router, message) do
        pid -> GenServer.cast(pid, { :message, message })
      end
    end
  end

  def get_options(context) do
    context.options
  end

  def get_state(context) do
    context.state
  end

  def update_state(context, f) do
    { :update_state, f.(context.state) }
  end

  defp validate_name!(name) do
    if !is_binary(name) && !is_atom(name) do
      raise ArgumentError, "name must be string or atom, got: #{inspect name}"
    end
  end

  defp validate_options!(specs, options) do
    valid_options = specs |> Map.new |> Map.keys
    Enum.each options, fn {k, _} ->
      if !Enum.member?(valid_options, k) do
        raise ArgumentError, "#{inspect k} is not a valid option"
      end
    end
  end

  defp start_workers(processor) do
    pids = Enum.map(1..processor.concurrency, fn i ->
      { :ok, pid } = GenServer.start_link(Tempest.Worker, nil)
      { i - 1, pid }
    end) |> Map.new
    %{ processor | pids: pids }
  end

  defp set_router(processor, router) do
    alias Tempest.Router

    router = router
      |> Router.from_options
      |> Router.set_pids(processor.pids)

    %{ processor | router: router }
  end

end
