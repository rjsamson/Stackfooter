defmodule Stackfooter.TestHelpers do
  def insert_user(attrs \\ %{}) do
    default_api_key = Application.get_env(:stackfooter, :bootstrap)[:default_api_key]
    default_account = Application.get_env(:stackfooter, :bootstrap)[:default_account]

    params = Dict.merge(%{
      username: default_account,
      password: "securepassword",
      api_keys: [default_api_key]
      }, attrs)

    changeset = Stackfooter.User.changeset(%Stackfooter.User{}, params)
    Stackfooter.Repo.insert!(changeset)
  end

  def reset_api_keys do
    Stackfooter.ApiKeyRegistry.reset_api_keys(Stackfooter.ApiKeyRegistry)

    default_api_key = Application.get_env(:stackfooter, :bootstrap)[:default_api_key]
    default_account = Application.get_env(:stackfooter, :bootstrap)[:default_account]

    # Default API key(s) to be added on application start.
    # Add more here, and in config/env.secret.exs

    Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, default_api_key, default_account)
  end
end
