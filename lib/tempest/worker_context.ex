defmodule Tempest.WorkerContext do
  defstruct [

    # { pid: name }
    incoming: %{},

    # [ { name, pids, options } ]
    outgoing: [],

    # #Mapset<[pid]>
    received_done_from: MapSet.new,

    # %Tempest.ProcessorContext{}
    processor_context: nil
  ]

end
