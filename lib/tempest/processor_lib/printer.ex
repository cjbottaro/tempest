# Write messages to a file (stdout by default).
defmodule Tempest.ProcessorLib.Printer do
  use Tempest.Processor

  option :dest, required: true, default: :stdout
  option :fn,   required: false

  def process(context, message) do
    %{ dest: dest, fn: f } = get_options(context)

    message = if f do
      f.(message)
    else
      message
    end

    case dest do
      :stdout  -> IO.puts(message)
      :devnull -> nil
    end
  end

end
