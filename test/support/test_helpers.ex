defmodule Stackfooter.TestHelpers do
  def insert_user(attrs \\ %{}) do
    params = Dict.merge(%{
      username: "user#{Base.encode16(:crypto.rand_bytes(8))}",
      password: "securepassword"
      }, attrs)

    changeset = Stackfooter.User.changeset(%Stackfooter.User{}, params)
    Stackfooter.Repo.insert!(changeset)
  end
end
