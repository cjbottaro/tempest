defmodule WordCount.Summary do
  use Tempest.Processor

  def process(_context, { word, count }) do
    IO.puts "#{word} #{count}"
  end

end
