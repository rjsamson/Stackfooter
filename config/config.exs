# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :stackfooter, Stackfooter.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "PIVh7s0WjKjUS/uxgCFoT40nhMSJvqlVfNBAePcPMdUCQg9m2f6uZDsx/M22t/4i",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: Stackfooter.PubSub,
           adapter: Phoenix.PubSub.PG2],
  http: [dispatch: [
         {:_, [
           {"/ob/api/ws/:trading_account/venues/:venue/tickertape/stocks/:stock", Stackfooter.TickerSocket, []},
           {"/ob/api/ws/:trading_account/venues/:venue/tickertape", Stackfooter.TickerSocket, []},
           {"/ob/api/ws/:trading_account/venues/:venue/executions/stocks/:stock", Stackfooter.ExecutionSocket, []},
           {"/ob/api/ws/:trading_account/venues/:venue/executions", Stackfooter.ExecutionSocket, []},
           {:_, Plug.Adapters.Cowboy.Handler, {Stackfooter.Endpoint, []}}
           ]}]]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false
