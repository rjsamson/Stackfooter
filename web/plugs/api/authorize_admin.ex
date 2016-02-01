defmodule Stackfooter.Plugs.Api.AuthorizeAdmin do
  use Stackfooter.Web, :controller
  alias Stackfooter.ApiKeyRegistry

  def init(options) do
    options
  end

  def call(conn, _) do
    case conn.assigns[:is_admin] do
      true ->
        conn
      false ->
        put_status(conn, 401) |> json(%{ok: false, error: "Invalid API key for that action."}) |> halt()
    end
  end
end
