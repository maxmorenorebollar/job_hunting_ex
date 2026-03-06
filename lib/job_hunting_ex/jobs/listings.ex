defmodule JobHuntingEx.Jobs.Listings do
  alias JobHuntingEx.Jobs.Listing

  def create(params) do
    %Listing{}
    |> Listing.changeset(params)
    |> JobHuntingEx.Repo.insert()
  end

  def create_all(params_list) do
    JobHuntingEx.Repo.transact(fn ->
      listings =
        Enum.reduce(params_list, [], fn params, acc ->
          case create(params) do
            {:ok, result} -> [result | acc]
            {:error, _reason} -> JobHuntingEx.Repo.rollback(:transaction_failed)
          end
        end)

      {:ok, listings}
    end)
  end
end
