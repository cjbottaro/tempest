# Apply a function to a message then emit the result.
defmodule Tempest.ProcessorLib.Function do
  use Tempest.Processor

  option :fn, required: true

  def process(context, message) do
    %{ fn: f } = get_options(context)
    emit(context, f.(message))
  end
end
