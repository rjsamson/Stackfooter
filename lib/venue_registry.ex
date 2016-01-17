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
    refs = %{}
    {:ok, {venue_names, refs}}
  end

  def handle_cast({:create, name, tickers}, {venue_names, refs}) do
    name = String.upcase(name)

    case lookup(venue_names, name) do
      {:ok, _pid} ->
        {:noreply, {venue_names, refs}}
      :error ->
        {:ok, pid} = Supervisor.start_child(Stackfooter.Venue.Supervisor, [String.upcase(name), tickers])
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(venue_names, {name, pid})
        {:noreply, {venue_names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {venue_names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(venue_names, name)
    {:noreply, {venue_names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
