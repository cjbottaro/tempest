# This just repeats messages (emits input unaltered).
defmodule Tempest.ProcessorLib.Repeater do
  use Tempest.Processor

  def process(context, message) do
    emit(context, message)
  end
end
