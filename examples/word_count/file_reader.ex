defmodule WordCount.FileReader do
  use Tempest.Processor

  # input: file name
  # output: lines
  def process(context, file_name) do
    File.open! file_name, [:read], fn f ->
      IO.stream(f, :line) |> Enum.each( &emit(context, &1) )
    end
  end

end
