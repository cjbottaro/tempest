defmodule Tempest.Processor do

  defmacro __using__(_) do
    quote do

      @initial_state nil
      @before_compile Tempest.Processor
      Module.register_attribute __MODULE__, :options, accumulate: true

      import Tempest.Processor.Dsl

      def done(_context) do
      end

      defoverridable [done: 1]

    end
  end

  defmacro __before_compile__(_) do
    quote do

      # This overwrites the initial_state/1 that was imported from
      # Processor.Dsl but that's fine because we're done with it at this point.
      def initial_state do
        @initial_state
      end

      def option_specs do
        @options
      end

      defstruct Enum.map(@options, fn {name, opts} -> { name, opts[:default] } end)

      def new(options \\ []) do
        Tempest.Processor.new(__MODULE__, options)
      end

    end
  end

  def get_options(processor) do
    option_names = Keyword.keys(processor.__struct__.option_specs)
    Map.take(processor, option_names)
  end

  def new(module, options) do
    struct = struct!(module, options)
    Enum.each module.option_specs, fn {name, spec} ->
      if spec[:required] && is_nil( Map.get(struct, name) ) do
        raise ArgumentError, "option #{inspect name} is required"
      end
    end
    struct
  end

end
