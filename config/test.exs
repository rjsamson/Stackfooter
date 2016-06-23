use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :stackfooter, Stackfooter.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :stackfooter, Stackfooter.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "stackfooter_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :stackfooter, :bootstrap,
  default_api_key: "4cy7uf63Lw2Sx6652YmLwBKy662weU4q",
  default_account: "admin"
