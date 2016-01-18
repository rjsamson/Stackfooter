defmodule Stackfooter.Plugs.Api.Authenticate do
  use Stackfooter.Web, :controller
  alias Stackfooter.ApiKeyRegistry

  def init(options) do
    options
  end

  def call(conn, _) do
    [token|t] = get_req_header(conn, "x-starfighter-authorization")

    case ApiKeyRegistry.lookup(ApiKeyRegistry, token) do
      {:ok, account} ->
        conn |> assign(:account, account)
      :error ->
        put_status(conn, 401) |> json(%{ok: false, error: "Invalid API key."}) |> halt()
    end
  end
end
