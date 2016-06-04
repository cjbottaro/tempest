defmodule WordCount.WordCounter do
  use Tempest.Processor

  initial_state %{}

  def process(context, word) do
    update_state context, fn state ->
      Map.update state, word, 1, &(&1 + 1)
    end
  end

  def done(context) do
    Enum.each get_state(context), &emit(context, &1)
  end

end
