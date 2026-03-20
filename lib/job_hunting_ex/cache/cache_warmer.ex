defmodule JobHuntingEx.Cache.Warmer do
  use Cachex.Warmer

  defp three_days_ago do
    -3
  end

  defp time_to_live do
    259_200_000
  end

  @impl true
  def execute(_state) do
    entries =
      JobHuntingEx.Queries.get_listings_from(three_days_ago())
      |> Enum.map(fn [url, _title, _company] = listing -> {url, listing} end)

    {:ok, entries, expire: time_to_live()}
  end
end
