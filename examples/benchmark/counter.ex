defmodule Counter do
  use Tempest.Processor

  initial_state 0

  def process(context, _message) do
    update_state context, fn state ->
      state + 1
    end
  end

  def done(context) do
    emit(context, get_state(context))
  end

end
