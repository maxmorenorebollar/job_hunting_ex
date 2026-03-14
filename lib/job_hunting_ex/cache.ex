defmodule JobHuntingEx.Cache do
  @moduledoc """
  Provides functions to interact with in-memory cache
  """
  alias JobHuntingEx.Jobs.Listings

  defp time_to_live() do
    259_200_000
  end

  def write_through(listings) do
    listings_as_kv =
      Enum.map(listings, fn listing -> {listing.url, listing} end)

    if listings_as_kv != [] do
      case Cachex.put_many(:cache, listings_as_kv, expire: time_to_live()) do
        {:ok, true} -> Listings.create_all(Enum.map(listings, &Map.from_struct/1))
        {:ok, false} -> {:error, :cache_failed}
      end
    else
      {:ok, []}
    end
  end
end
