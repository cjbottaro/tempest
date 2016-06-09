# This just swallows messages (input is anything, emits nothing).
defmodule Tempest.ProcessorLib.Null do
  use Tempest.Processor

  def process(_, _) do
  end
end
