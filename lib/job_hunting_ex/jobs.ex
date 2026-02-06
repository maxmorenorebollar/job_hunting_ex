defmodule JobHuntingEx.Jobs do
  alias Jobs.Listing

  def create_listing(params) do
    %Jobs.Listing{}
    |> Jobs.Listing.changeset(params)
    |> Jobs.Repo.insert()
  end
end
