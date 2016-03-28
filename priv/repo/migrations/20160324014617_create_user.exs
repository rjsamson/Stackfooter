defmodule Stackfooter.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :password_hash, :string
      add :api_keys, {:array, :string}

      timestamps
    end

  end
end
