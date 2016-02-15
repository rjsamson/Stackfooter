defmodule Stackfooter.SettlementDeskTest do
  use ExUnit.Case, async: true
  alias Stackfooter.{SettlementDesk, Order.Fill}

  test "tests position_or_new_position" do
    SettlementDesk.reset_accounts(SettlementDesk)
    :timer.sleep(20)
    SettlementDesk.settle_transaction(SettlementDesk, %{buy_account: "RJSAMSON", sell_account: "ADMIN", stock: "NYC", fill: %Fill{price: 100, qty: 10}})
    :timer.sleep(20)
    SettlementDesk.settle_transaction(SettlementDesk, %{buy_account: "RJSAMSON", sell_account: "ADMIN", stock: "FOO", fill: %Fill{price: 100, qty: 10}})
    :timer.sleep(20)

    accounts = SettlementDesk.all_accounts(SettlementDesk)

    expected_accounts = [%Stackfooter.SettlementDesk.Account{cash: 2000, name: "ADMIN", nav: 0,
            positions: [%Stackfooter.SettlementDesk.Account.Position{price: 0, qty: -10, stock: "FOO"},
              %Stackfooter.SettlementDesk.Account.Position{price: 0, qty: -10, stock: "NYC"}]},
              %Stackfooter.SettlementDesk.Account{cash: -2000, name: "RJSAMSON", nav: 0,
            positions: [%Stackfooter.SettlementDesk.Account.Position{price: 0, qty: 10, stock: "FOO"},
              %Stackfooter.SettlementDesk.Account.Position{price: 0, qty: 10, stock: "NYC"}]}]

    assert accounts == expected_accounts
  end
end
