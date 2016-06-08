defmodule Tempest.Processor.Printer do
  use Tempest.Processor

  option :dest, required: true, default: :stdout

  def process(context, string) do
    case get_options(context) do
      %{ dest: :stdout } -> IO.puts(string)
      %{ dest: :devnull } -> nil
    end
  end

end
