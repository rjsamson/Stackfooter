defmodule Stackfooter.ScoreController do
  use Stackfooter.Web, :controller

  plug Stackfooter.Plugs.Api.Authenticate when action in [:score]

  alias Stackfooter.{Venue, VenueRegistry, SettlementDesk, SettlementDesk.Account}

  def all_scores(conn, _params) do
    stock_quotes = get_stock_quotes
    accounts = SettlementDesk.all_accounts(SettlementDesk)
    accounts = Enum.map(accounts, fn account ->
      %{account | nav: Account.calculate_nav(account, stock_quotes),
                  positions: Account.update_positions(account, stock_quotes),
                  name: Account.sanitize_account_name(account.name)}
    end)

    conn |> json(%{"ok" => true, "scores" => accounts})
  end

  def score(conn, %{"account" => account_name}) do
    stock_quotes = get_stock_quotes

    if String.upcase(account_name) == conn.assigns[:account] do
      {:ok, account} = SettlementDesk.lookup(SettlementDesk, account_name)

      account = %{account | nav: Account.calculate_nav(account, stock_quotes),
                            positions: Account.update_positions(account, stock_quotes)}
      conn |> json(%{"ok" => true, "account" => account})
    else
      put_status(conn, 401) |> json(%{"ok" => false, "error" => "You don't have permission to access that account"})
    end
  end

  defp get_stock_quotes do
    Enum.reduce(VenueRegistry.all_venues(VenueRegistry), %{}, fn(venue, acc) ->
      {:ok, tickers} = Venue.tickers(venue)
      Enum.reduce(tickers, acc, fn(ticker, accum) ->
        {:ok, stock_quote} = Venue.get_quote(venue, ticker.symbol)
        Map.put(accum, ticker.symbol, stock_quote["last"])
      end)
    end)
  end
end
