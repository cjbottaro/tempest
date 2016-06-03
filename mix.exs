defmodule Tempest.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tempest,
      version: "0.0.1",
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      elixirc_paths: elixirc_paths(Mix.env)
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :postgrex, :ecto, :memcache_client]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ecto, "~> 2.0-rc"},
      {:postgrex, "~> 0.11.0"},
      {:memcache_client, "~> 1.0.0"}
    ]
  end

  defp elixirc_paths(:examples) do
    ["lib", "examples"]
  end

  defp elixirc_paths(_) do
    ["lib"]
  end

end
