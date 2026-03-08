defmodule JobHuntingEx.Cache do
  alias JobHuntingEx.Jobs.Listings

  defp time_to_live() do
    259_200_000
  end

  def write_through(listings) do
    listings_as_kv =
      Enum.map(listings, fn listing -> {listing.url, listing} end)

    if listings_as_kv != [] do
      with {:ok, true} <- Cachex.put_many(:cache, listings_as_kv, expire: time_to_live()) do
        Listings.create_all(Enum.map(listings, &Map.from_struct/1))
      else
        {:ok, false} -> {:error, :cache_failed}
      end
    else
      {:ok, []}
    end
  end
end
