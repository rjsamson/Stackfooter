defmodule Stackfooter.TestHelpers do
  def insert_user(attrs \\ %{}) do
    params = Dict.merge(%{
      username: "user#{Base.encode16(:crypto.rand_bytes(8))}",
      password: "securepassword"
      }, attrs)

    changeset = Stackfooter.User.changeset(%Stackfooter.User{}, params)
    Stackfooter.Repo.insert!(changeset)
  end

  def set_api_keys do
    Stackfooter.ApiKeyRegistry.reset_api_keys(Stackfooter.ApiKeyRegistry)

    default_api_key = Application.get_env(:stackfooter, :bootstrap)[:default_api_key]
    default_account = Application.get_env(:stackfooter, :bootstrap)[:default_account]

    # Default API key(s) to be added on application start.
    # Add more here, and in config/env.secret.exs

    Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, default_api_key, default_account)
  end
end
