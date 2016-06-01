use Mix.Config

config :tempest, ecto_repos: [Tempest.Repo]

config :tempest, Tempest.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "shard_dev_development_master",
  username: "cjbottaro"

config :memcache_client,
  host: "127.0.0.1",
  port: 11211,
  auth_method: :none,
  username: "",
  password: "",
  pool_size: 10,
  pool_max_overflow: 20,
  transcoder: Memcache.Client.Transcoder.Erlang
