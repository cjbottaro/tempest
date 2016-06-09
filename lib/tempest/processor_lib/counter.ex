# Counts messages (maybe based on a transformation function) then on done,
# emits tuples for each count: {count, message}.
defmodule Tempest.ProcessorLib.Counter do
  use Tempest.Processor

  # If give, transform the message with this function before counting.
  option :fn

  initial_state %{}

  def process(context, message) do
    case get_options(context) do
      %{ fn: nil  } -> count(context, message)
      %{ fn: func } -> count(context, func.(message))
    end
  end

  def done(context) do
    Enum.each get_state(context), fn {message, count} ->
      emit(context, {count, message})
    end
  end

  defp count(context, message) do
    update_state context, fn state ->
      Map.update state, message, 1, &(&1 + 1)
    end
  end

end
