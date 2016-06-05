defmodule DistributedJoin.FileReader do
  use Tempest.Processor

  # def process(context, records) do
  #   Enum.each records, &emit(context, &1)
  # end

  def process(context, file_name) do
    File.open! file_name, [:read], fn f ->
      IO.stream(f, :line)
        |> Enum.each(&process_line(context, &1))
    end
  end

  defp process_line(context, line) do
    tuple = String.rstrip(line)
      |> String.split(",")
      |> List.to_tuple

    emit(context, tuple)
  end

end
