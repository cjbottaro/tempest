defmodule RangeEmitter do
  use Tempest.Processor

  def process(context, {lower, upper}) do
    Enum.each lower..upper, fn i ->
      emit(context, i)
    end
  end

end
