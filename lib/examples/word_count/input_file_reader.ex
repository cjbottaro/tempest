defmodule InputFileReader do
  use Tempest.Processor

  def process(topo, state, file_name) do
    File.open! file_name, [:read], fn f ->
      IO.stream(f, :line) |> Enum.each(fn line ->
        String.split(line, " ")
          |> Enum.each(&emit(topo, &1))
      end)
    end

    state
  end

end
