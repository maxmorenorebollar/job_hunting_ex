defmodule JobHuntingEx.Jobs do
  alias Jobs.Listing

  def create_listing(params) do
    %Listing{}
    |> Listing.changeset(params)
    |> Jobs.Repo.insert()
  end
end
