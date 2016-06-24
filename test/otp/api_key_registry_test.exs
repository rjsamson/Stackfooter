defmodule Stackfooter.ApiKeyRegistryTest do
  use ExUnit.Case, async: true
  alias Stackfooter.ApiKeyRegistry

  setup do
    Stackfooter.ApiKeyRegistry.reset_api_keys(Stackfooter.ApiKeyRegistry)
    Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "4cy7uf63Lw2Sx6652YmLwBKy662weU4q", "admin")
    Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "7eWeGhc8n0va5bjT66C0Vl1fBw2618BJ", "rjsamson")

    :ok
  end

  test "returns all existing account names" do
    all_accounts = ApiKeyRegistry.all_account_names(ApiKeyRegistry)

    assert all_accounts == ["RJSAMSON", "ADMIN"]
  end

  test "resets all API keys" do
    Stackfooter.ApiKeyRegistry.reset_api_keys(Stackfooter.ApiKeyRegistry)
    all_accounts = ApiKeyRegistry.all_account_names(ApiKeyRegistry)

    assert all_accounts == []
  end
end
