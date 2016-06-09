# Tempest

Framework for distributed job topologies in Elixir (heavily influenced by
Apache Storm).

The goal of this project is to be able to _very easily_ create and run
parallel/distributed job topologies. If you want something that is difficult,
just use Apache Storm.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add tempest to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:tempest, "~> 0.0.1"}]
end
```

  2. Ensure tempest is started before your application:

```elixir
def application do
  [applications: [:tempest]]
end
```

## Quickstart

**IMPORTANT**: You need git-lfs installed to run the examples.

```bash
git clone https://github.com/cjbottaro/tempest.git
cd tempest
MIX_ENV=examples mix deps.get
MIX_ENV=examples mix compile
MIX_ENV=examples mix run examples/benchmark.exs
MIX_ENV=examples mix run examples/appender.exs /usr/share/dict/words
MIX_ENV=examples mix run examples/word_count.exs examples/data/big.txt
MIX_ENV=examples mix run examples/distributed_join.exs
```

## Building your first topology

What is a topology? A topology describes a computation: a pipeline of jobs.
It's a graph that specifies each job's dependencies and amount of parallelism.

So let's make a very simple topology that reads a file from the filesystem,
then outputs each line with "!!" appended to it.

The topology will have three processors, linked together like this:

![](http://d.pr/i/17GX5+)

Processors are conceptually just functions. The input of a processor is a
_single_ tuple and the output is _zero or more_ tuples.

When I say _tuple_, I really just mean any kind of struct, map, list, tuple,
primitive type, etc. In Ruby or Python, it would just be an "object".

So let's build the `reader` processor. The input will be a file path and the
output will be the lines in that file.

```elixir
defmodule Reader do
  use Tempest.Processor

  def process(context, file_name) do
    stream = File.stream!(file_name, [:read])
    Enum.each stream, fn line ->
      line = String.rstrip(line)
      emit(context, line)
    end
  end
end
```

Pretty simple, huh?

Don't worry about `context`, it's like the opaque and ubiquitous `conn` in
Phoenix.

Let's build the `appender` processor next.

```elixir
defmodule Appender do
  use Tempest.Processor

  def process(context, line) do
    emit(context, "#{line}!!")
  end
end
```

Then the `printer` processor.

```elixir
defmodule Printer do
  use Tempest.Processor

  def process(context, exclaimed_line) do
    IO.puts(exclaimed_line)
  end
end
```

Now let's build the topology.

```elixir
alias Tempest.Topology

topology = Topology.new
  |> Topology.add_processor(:my_reader, Reader)
  |> Topology.add_processor(:the_appender, Appender, concurrency: 2)
  |> Topology.add_processor(:our_printer, Printer)

  |> Topology.add_link(:my_reader, :the_appender)
  |> Topology.add_link(:the_appender, :our_printer)
```

Notice that we name each processor in the calls to `add_processor` so that
we can link them by name in the calls to `add_link`.

Also notice we passed `concurrency: 2` to the `Appender` processor. That means
it will run in two processes, and our topology really looks like this:

![](http://d.pr/i/FWlZ+)

Now let's run the topology...

```elixir
topology = topology
  |> Topology.begin_computation
  |> Topology.emit(:reader, "/usr/share/dict/words")
  |> Topology.end_computation
```

... and it should print out each line in `/usr/share/dict/words` with `!!` appended
to them.

## Statistics (finding bottlenecks in your topology)

To print out stats about your computation, just tack on...

```elixir
topology
  |> Tempest.Stats.get
  |> Tempest.Stats.pretty_print
```

... and you should be able to analyze any bottlenecks in your computation.

_TODO: explain the stats._

## Stdlib of processors

The main goal of Tempest is ease of use; it ships with "a standard library
of processors". A lot of topologies can be built without any custom processor
definitions (including the README example and all examples in `examples/`),
just use the processors in `Tempest.ProcessorLib`.

## Goals (TODOs)

* Distribute processors; currently all processors run in a single BEAM VM... :(
* Rename "processors" to something more interesting.
* A lot more error handling (enhance user experience).
