alias Tempest.{Topology, Processor, Router, Stats}
alias Tempest.ProcessorLib.Repeater
alias Benchmark.{Range, Counter, Summer}

defmodule Benchmark.Range do
  use Processor

  def process(context, {lower, upper}) do
    Enum.each lower..upper, fn i ->
      emit(context, i)
    end
  end
end

defmodule Benchmark.Counter do
  use Processor

  initial_state 0

  def process(context, _) do
    update_state context, fn state ->
      state + 1
    end
  end

  def done(context) do
    count = get_state(context)
    emit(context, count)
  end
end

defmodule Benchmark.Summer do
  use Processor

  initial_state 0

  def process(context, count) do
    update_state context, fn state ->
      state = state + count
    end
  end

  def done(context) do
    get_state(context) |> IO.puts
  end
end

Topology.new
  |> Topology.add_processor(:input,    Range,    concurrency: 4, router: Router.Shuffle)
  |> Topology.add_processor(:repeater, Repeater, concurrency: 4)
  |> Topology.add_processor(:counter,  Counter,  concurrency: 4)
  |> Topology.add_processor(:printer,  Summer)

  |> Topology.add_link(:input,    :repeater)
  |> Topology.add_link(:repeater, :counter)
  |> Topology.add_link(:counter,  :printer)

  |> Topology.begin_computation
  |> Topology.emit(:input, {1, 1_000_000})
  |> Topology.emit(:input, {1, 1_000_000})
  |> Topology.emit(:input, {1, 1_000_000})
  |> Topology.emit(:input, {1, 1_000_000})
  |> Topology.end_computation

  |> Stats.get
  |> Stats.pretty_print
