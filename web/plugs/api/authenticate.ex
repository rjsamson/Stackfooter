defmodule Stackfooter.Plugs.Api.Authenticate do
  use Stackfooter.Web, :controller
  alias Stackfooter.ApiKeyRegistry

  def init(options) do
    options
  end

  def call(conn, _) do
    [token|_t] = get_req_header(conn, "x-starfighter-authorization")

    case ApiKeyRegistry.lookup(ApiKeyRegistry, token) do
      {:ok, "ADMIN" = account} ->
        conn |> assign(:account, account) |> assign(:is_admin, true)
      {:ok, account} ->
        conn |> assign(:account, account) |> assign(:is_admin, false)
      :error ->
        put_status(conn, 401) |> json(%{ok: false, error: "Invalid API key."}) |> halt()
    end
  end
end
