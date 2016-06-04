defmodule Summer do
  use Tempest.Processor

  initial_state 0

  def process(context, count) do
    update_state context, fn state ->
      state + count
    end
  end

  def done(context) do
    IO.puts get_state(context)
  end

end
