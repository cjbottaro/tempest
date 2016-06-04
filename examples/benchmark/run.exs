alias Tempest.Topology
alias Tempest.Processor.Identity

defmodule RangeEmitter do
  use Tempest.Processor

  def process(context, {lower, upper}) do
    Enum.each lower..upper, fn i ->
      emit(context, i)
    end
  end

end

defmodule Counter do
  use Tempest.Processor

  initial_state 0

  def process(context, _message) do
    update_state context, fn state ->
      state + 1
    end
  end

  def done(context) do
    emit(context, get_state(context))
  end

end

defmodule Summer do
  use Tempest.Processor

  initial_state 0

  def process(context, count) do
    update_state context, fn state ->
      state + count
    end
  end

  def done(context) do
    IO.puts get_state(context)
  end

end

# input --> repeater --> counter --\
# input --> repeater --> counter ---\
#                                    |--> summer
# input --> repeater --> counter ---/
# input --> repeater --> counter --/
topology = Topology.new
  |> Topology.add_processor(:input, RangeEmitter, concurrency: 4, router: :shuffle)
  |> Topology.add_processor(:repeater, Identity, concurrency: 4)
  |> Topology.add_processor(:counter, Counter, concurrency: 4)
  |> Topology.add_processor(:summer, Summer)

  |> Topology.add_link(:input, :repeater)
  |> Topology.add_link(:repeater, :counter)
  |> Topology.add_link(:counter, :summer)
  |> Topology.start

start_time = :os.system_time(:milli_seconds)

topology
  |> Topology.emit(:input, {1, 1_000_000})
  |> Topology.emit(:input, {1, 1_000_000})
  |> Topology.emit(:input, {1, 1_000_000})
  |> Topology.emit(:input, {1, 1_000_000})
  |> Topology.stop

end_time = :os.system_time(:milli_seconds)

IO.puts (end_time - start_time) / 1000.0
