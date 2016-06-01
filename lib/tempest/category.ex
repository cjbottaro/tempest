defmodule Tempest.Application do
  use Ecto.Schema

  schema "categories" do
    field :name, :string
    field :state, :string
  end

end
