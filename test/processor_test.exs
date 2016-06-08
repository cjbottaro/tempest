defmodule ProcessorTest do
  use ExUnit.Case
  doctest Tempest

  alias Tempest.Processor

  test "building a simple processor" do
    processor = Processor.Null.new
    assert Processor.get_options(processor) == %{}
  end

  test "building a processor with invalid options" do

    assert_raise KeyError, ~r/:blah/, fn ->
      Processor.Null.new(blah: :test)
    end

    assert_raise KeyError, ~r/:pids/, fn ->
      Processor.Null.new(pids: %{})
    end

    assert_raise KeyError, ~r/:concurrency/, fn ->
      Processor.Null.new(concurrency: 2)
    end

  end

  test "building a processor with options" do
    processor = Processor.EquiJoin.new join_fn: &(&1)
    assert %{ join_fn: join_fn, output_fn: output_fn} = processor
    assert is_function(join_fn)
    assert is_nil(output_fn)
  end

  defmodule ProcessorWithRequiredOptions do
    use Processor
    option :foo, required: true
    option :bar, required: false
  end

  test "required options are required" do
    assert_raise ArgumentError, ~r/:foo/, fn ->
      ProcessorWithRequiredOptions.new
    end
  end

end
