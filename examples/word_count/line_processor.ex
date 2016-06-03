defmodule WordCount.LineProcessor do
  use Tempest.Processor

  # Input: line
  # Ouput: words
  def process(context, line) do
    Regex.replace(~r/[^'A-Za-z0-9]/, line, " ")
      |> String.downcase
      |> String.split(" ")
      |> Enum.map(&String.strip/1)
      |> Enum.filter(&(&1 != ""))
      |> Enum.map(&emit(context, &1))
  end

end
