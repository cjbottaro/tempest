defmodule Tempest.Topology.Component do
  defstruct [
    processor: nil,
    concurrency: 1,
    router: Tempest.Router.Random,
    worker_pids: nil
  ]

  def new(attributes \\ []) do
    struct!(__MODULE__, attributes)
      |> start_workers
      |> build_router
  end

  defp start_workers(component) do
    alias Tempest.Worker

    %{ concurrency: concurrency, processor: processor } = component

    worker_pids = Enum.map 1..concurrency, fn _ ->
      {:ok, pid} = GenServer.start_link(Worker, processor)
      pid
    end

    %{ component | worker_pids: worker_pids }
  end

  defp build_router(component) do
    alias Tempest.Router

    %{ router: router, worker_pids: worker_pids } = component

    # Bleh, convert list into tuple
    router = if is_list(router) do
      List.to_tuple(router)
    else
      router
    end

    router = case router do
      { module, options } ->
        module.new(options)
      module when is_atom(module) ->
        module.new
      router when is_map(router) ->
        router
    end

    router = Router.set_pids(router, worker_pids)

    %{ component | router: router }
  end

end
