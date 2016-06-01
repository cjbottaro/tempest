defmodule Tempest.Processor do

  defmacro __using__(_) do
    quote do
      use GenServer

      alias Tempest.Topology

      def initial_state do
        %{}
      end

      def done(topo, state) do
      end

      defoverridable [initial_state: 0, done: 2]

      def init(_state) do
        state = %{
          topo: nil,
          upstream_finished: %MapSet{},
          processor_state: apply(__MODULE__, :initial_state, [])
        }
        { :ok, state }
      end

      def handle_call { :set_topo, topo }, _from, state do
        { :reply, :ok, Map.put(state, :topo, topo) }
      end

      def handle_cast { :ingest, tuple }, state do
        %{ topo: topo, processor_state: processor_state } = state
        processor_state = process(topo, processor_state, tuple)
        { :noreply, Map.put(state, :processor_state, processor_state) }
      end

      def handle_call :done, from, state do
        { from_pid, _ } = from

        state = Map.update! state, :upstream_finished, fn set ->
          MapSet.put(set, from_pid)
        end

        needed = state.topo
          |> Topology.get_incoming_pids(__MODULE__)
          |> MapSet.new

        # IO.puts "#{inspect __MODULE__} #{inspect self}"
        # IO.puts "done from #{inspect from_pid}"
        # IO.puts "needed #{inspect needed}"
        # IO.puts "finished #{inspect state.upstream_finished}\n"

        if MapSet.size(needed) == 0 || needed == state.upstream_finished do
          done(state.topo, state.processor_state)
          state.topo
            |> Topology.get_outgoing_pids(__MODULE__)
            |> Enum.each(fn pid ->
              GenServer.call(pid, :done, :infinity)
            end)
        end

        { :reply, :ok, state }
      end

      def emit(topo, struct) do
        topo
          |> Topology.get_outgoing_links(__MODULE__)
          |> Enum.each(fn { src, dst, type, options } ->
            %{ pids: pids, concurrency: concurrency } = topo.processors[dst]
            pid = case type do
              :group -> get_group_pid(struct, pids, concurrency, options)
              :shuffle -> get_shuffle_pid(pids, concurrency)
            end
            GenServer.cast(pid, { :ingest, struct })
          end)
      end

      defp get_shuffle_pid(pids, n) do
        n = :rand.uniform(n) - 1
        Enum.at(pids, n)
      end

      defp get_group_pid(struct, pids, n, options) do
        value = case options do
          %{ func: func } ->
            raise "implement"
          %{ key: key } ->
            raise "implement"
          _ ->
            struct
        end

        int = :binary.decode_unsigned(value)
        Enum.at(pids, rem(int, n))
      end

    end
  end

end
