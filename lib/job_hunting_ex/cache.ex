defmodule JobHuntingEx.Cache do
  @moduledoc """
  Provides functions to interact with in-memory cache
  """
  alias JobHuntingEx.Jobs.Listings

  defp time_to_live() do
    259_200_000
  end

  @spec write_through([]) :: {:ok, []}
  def write_through(listings) when listings == [] do
    {:ok, []}
  end

  @spec write_through(list(map())) ::
          {:ok, list(map())} | {:error, :transaction_failed} | {:error, :cache_failed}
  def(write_through(listings)) do
    listings_as_kv =
      Enum.map(listings, fn listing -> {listing.url, listing} end)

    with {:ok, listings} <- Listings.create_all(Enum.map(listings, &Map.from_struct/1)),
         {:ok, true} <- Cachex.put_many(:cache, listings_as_kv, expire: time_to_live()) do
      {:ok, listings}
    else
      {:error, :transaction_failed} -> {:error, :transaction_failed}
      {:ok, false} -> {:error, :cache_failed}
    end
  end
end
