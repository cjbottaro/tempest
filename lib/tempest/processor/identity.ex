defmodule Tempest.Processor.Identity do
  use Tempest.Processor

  def process(context, message) do
    emit(context, message)
  end
end
