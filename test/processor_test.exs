defmodule ProcessorTest do
  use ExUnit.Case
  doctest Tempest

  alias Tempest.{Processor, Router}

  test "building a simple processor" do
    processor = Processor.Null.new(:foo)
    assert processor.name == :foo
    assert processor.concurrency == 1
    assert %Router.Random{} = processor.router
  end

  test "building a processor with invalid options" do

    assert_raise ArgumentError, ~r/:blah/, fn ->
      Processor.Null.new(:foo, blah: :test)
    end

    assert_raise ArgumentError, ~r/:pids/, fn ->
      Processor.Null.new(:foo, pids: %{})
    end

  end

  test "building a processor with a complex router" do
    processor = Processor.Null.new :foo, router: { :group, fn: &(&1.bar) }
  end


end
