defmodule Tempest.Repo do
  if Mix.env != :test do
    use Ecto.Repo, otp_app: :tempest
  end
end
