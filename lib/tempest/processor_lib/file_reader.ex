# Reads a file and emits the contents.
defmodule Tempest.ProcessorLib.FileReader do
  use Tempest.Processor

  option :emit, required: true, default: :lines
  option :strip, default: true

  def process(context, file_name) do
    file = File.stream!(file_name, [:read])

    case get_options(context) do
      %{ emit: :lines } -> emit_lines(context, file)
      %{ emit: :words } -> emit_words(context, file)
    end
  end

  defp emit_lines(context, file) do
    Enum.each file, fn line ->
      maybe_strip(context, line)
    end
  end

  defp emit_words(context, file) do
    Enum.each file, fn line ->
      String.split(line, " ") |> Enum.each( &maybe_strip(context, &1) )
    end
  end

  defp maybe_strip(context, string) do
    case get_options(context) do
      %{ strip: true } ->
        stripped = String.strip(string)
        emit(context, stripped)
      %{ strip: false } ->
        emit(context, string)
    end
  end

end
