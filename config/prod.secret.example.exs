use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :stackfooter, Stackfooter.Endpoint,
  secret_key_base: "run-mix-phoenix.gen.secret-and-paste-result-here"

# Configure your database
config :stackfooter, Stackfooter.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "username",
  password: "password",
  database: "stackfooter_prod",
  pool_size: 20

config :stackfooter, :bootstrap,
  default_api_key: "I1kaUrr1SN6HK6i870d54awmLlk76d06",
  default_account: "rjsamson1124"
