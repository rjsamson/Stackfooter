defmodule Stackfooter.SettlementDesk do
  alias Stackfooter.Order.Fill

  defmodule Account do
    defmodule Position do
      defstruct stock: "", qty: 0
    end

    defstruct name: "", value: 0, positions: []
  end

  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def init(table) do
    accounts = :ets.new(table, [:named_table, read_concurrency: true])
    {:ok, accounts}
  end

  def settle_transaction(table, %{buy_account: buy_account_name, sell_account: sell_account_name, stock: stock, fill: fill}) do
    GenServer.cast(table, {:settle_transaction, buy_account_name, sell_account_name, stock, fill})
  end

  def lookup(table, name) when is_atom(table) do
    name = String.upcase(name)
    case :ets.lookup(table, name) do
      [{^name, account}] -> {:ok, account}
      [] ->
        account = %Account{name: name}
        :ets.insert(table, {name, account})
        {:ok, account}
    end
  end

  def handle_cast({:settle_transaction, buy_account_name, sell_account_name, stock, fill}, accounts) do
    buy_account =
      case lookup(accounts, buy_account_name) do
        {:ok, account} ->
          account
        _ ->
          %Account{name: buy_account_name}
      end

    sell_account =
      case lookup(accounts, sell_account_name) do
        {:ok, account} ->
          account
        _ ->
          %Account{name: sell_account_name}
      end

    price = fill.price
    quantity = fill.qty
    amount = price * quantity

    buy_position = position_for_stock(buy_account.positions, stock)
    sell_position = position_for_stock(sell_account.positions, stock)

    remaining_buy_positions = buy_account.positions -- [buy_position]
    remaining_sell_positions = sell_account.positions -- [sell_position]

    new_buy_position_qty = buy_position.qty + quantity
    buy_position = %{buy_position | qty: new_buy_position_qty}

    new_sell_position_qty = sell_position.qty - quantity
    sell_position = %{sell_position | qty: new_sell_position_qty}

    new_buy_account_value = buy_account.value - amount
    new_sell_account_value = sell_account.value + amount

    buy_account = %{buy_account | value: new_buy_account_value,
                                  positions: [buy_position] ++ remaining_buy_positions}

    sell_account = %{sell_account | value: new_sell_account_value,
                                    positions: [sell_position] ++ remaining_sell_positions}

    :ets.insert(accounts, {buy_account_name, buy_account})
    :ets.insert(accounts, {sell_account_name, sell_account})

    {:noreply, accounts}
  end

  defp position_for_stock([], stock) do
    %Account.Position{stock: stock}
  end

  defp position_for_stock(positions, stock) do
    positions
    |> Enum.filter(fn pos ->
      pos.stock == stock
    end)
    |> position_or_new_position(stock)
  end

  defp position_or_new_position([], stock) do
    %Account.Position{stock: stock}
  end

  defp position_or_new_position(position, _) when is_list(position) do
    position |> List.first
  end
end
