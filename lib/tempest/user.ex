defmodule Tempest.User do
  use Ecto.Schema

  schema "users" do
    field :display_name, :string
    field :email, :string
  end

end
