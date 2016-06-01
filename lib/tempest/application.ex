defmodule Tempest.Application do
  use Ecto.Schema

  schema "applications" do
    field :opportunity_id, :integer
    field :user_id, :integer
  end

end
