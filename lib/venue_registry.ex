defmodule Stackfooter.VenueRegistry do
  alias Stackfooter.Venue
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def lookup(pid, name) when is_atom(pid) do
    name = String.upcase(name)

    case :ets.lookup(pid, name) do
      [{^name, venue}] -> {:ok, venue}
      [] -> :error
    end
  end

  def create(pid, name, tickers) do
    GenServer.cast(pid, {:create, name, tickers})
  end

  def init(table) do
    venue_names = :ets.new(table, [:named_table, read_concurrency: true])
    {:ok, venue_names}
  end

  def handle_cast({:create, name, tickers}, venue_names) do
    name = String.upcase(name)

    case lookup(venue_names, name) do
      {:ok, _pid} ->
        {:noreply, venue_names}
      :error ->
        {:ok, pid} = Supervisor.start_child(Stackfooter.Venue.Supervisor, [name, tickers])
        name_atom = String.to_atom(name)
        :ets.insert(venue_names, {name, name_atom})
        {:noreply, venue_names}
    end
  end
end
