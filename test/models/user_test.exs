defmodule Stackfooter.UserTest do
  use Stackfooter.ModelCase

  alias Stackfooter.User

  @valid_attrs %{api_keys: ["some content"], password: "some content", username: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end
