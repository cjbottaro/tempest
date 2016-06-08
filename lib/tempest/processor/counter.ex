defmodule Tempest.Processor.Counter do
  use Tempest.Processor

  initial_state %{}

  option :fn

  def process(context, thing) do
    case get_options(context) do
      %{ fn: nil  } -> count(context, thing)
      %{ fn: func } -> count(context, func.(thing))
    end
  end

  def done(context) do
    Enum.each get_state(context), fn {word, count} ->
      emit(context, "#{word} #{count}")
    end
  end

  defp count(context, thing) do
    update_state context, fn state ->
      Map.update state, thing, 1, &(&1 + 1)
    end
  end

end
