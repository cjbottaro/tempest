defmodule ApplicationEmitter do
  use Tempest.Processor

  alias Tempest.{Repo, Application}

  def process(topo, state, _) do
    Repo.all(Application) |> Enum.each(&emit(topo, &1))
  end

end
