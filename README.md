# Stackfooter
[![Build Status](https://travis-ci.org/rjsamson/Stackfooter.svg?branch=master)](https://travis-ci.org/rjsamson/Stackfooter)[![Coverage Status](https://coveralls.io/repos/github/rjsamson/Stackfooter/badge.svg?branch=master)](https://coveralls.io/github/rjsamson/Stackfooter?branch=master)

A [Stockfighter](https://www.stockfighter.io) clone built in Elixir using Phoenix.

## What is it?

Right now Stackfooter implements all of the base Stockfighter API (the GM API is not supported).
Documentation for the Stockfighter API can be found here: [https://starfighter.readme.io](https://starfighter.readme.io).
Position tracking and user scores have been added, as well as websockets implementing the full production
Stockfighter API. Scores are available in JSON format at stackfooter.rjsamson.org/ob/api/scores, and scores for a specific account are available at /ob/api/scores/:account. Performance metrics are now also available at /beaker.

## How do I use it?

This project is in pretty much constant flux at the moment, so until there's a proper web interface
to spin up venues, add api keys and accounts, add tickers, etc, the easiest way to play around
with Stackfooter is to do the following:

  1. Install [Elixir](https://www.elixir-lang.org)
  2. Install dependencies with `mix deps.get`
  3. Create a dev.secret.exs file to populate an API key `cp config/dev.secret.example.exs config/dev.secret.exs`
  4. Add any additional API keys / accounts or venues / tickers to lib/stackfooter/bootstrap.ex
  5. Start phoenix in iex mode with `iex -S mix phoenix.server`
  6. Use the API as you usually would at http://localhost:4000 with the API keys and Venue from the config

## TODO

  * ~~Performance improvements in the Venue GenServer~~
  * ~~Full API compatibility~~
  * ~~Settlement Desk for position tracking~~
  * ~~Scores API~~
  * ~~Bootstrap with default venues and API keys~~
  * ~~Websockets~~
  * ~~Clean up ugly and redundant code in the Venue!~~
  * ~~Improve Venue performance for closed orders~~
  * Add JSON API for configuration and control of Venues / Tickers
  * Web interface for setup and control

## Thanks

Thanks to danielvf and amtiskaw for some pointers, and again to amtiskaw for the excellent
test script to work out some last minute inconsistencies. Also, big thanks to patio11 for
making Stockfighter!
