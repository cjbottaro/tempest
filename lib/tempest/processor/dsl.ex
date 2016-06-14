defmodule Tempest.Processor.Dsl do

  @valid_option_options ~w(required default)

  defmacro initial_state(state) do
    quote do
      @initial_state unquote(state)
    end
  end

  defmacro option(name, options \\ []) do
    check_option_name!(name)
    check_option_options!(options)

    quote bind_quoted: [name: name, options: options] do
      @options { name, options }
    end
  end

  def emit(context, message) do
    worker = context # That's really what it is.
    Enum.each worker.routers, fn router ->
      pid = Tempest.Router.route(router, message)
      GenServer.cast pid, { :message, message }
    end
    :ets.update_counter(context.stats.emit_count_ets, :emit_count, 1)
  end

  def get_options(context) do
    context.processor_options
  end

  def get_state(context) do
    context.processor_state
  end

  def update_state(context, func) do
    {:__tempest_update_state__, func.(context.processor_state)}
  end

  defp check_option_name!(name) do
    if !is_atom(name) do
      raise ArgumentError, "option name must be atom, got #{inspect name}"
    end
  end

  defp check_option_options!(options) do
    Enum.each options, fn {k, _} ->
      if Enum.member?(@valid_option_options, k) do
        raise ArgumentError, "#{inspect k} is not a valid option"
      end
    end
  end

end
