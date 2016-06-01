defmodule Tempest.Processor.Application do
  use Tempest.Processor

  def process(topo, state, application) do
    emit(topo, application)
    state
  end

end
