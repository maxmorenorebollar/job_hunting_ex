defmodule JobHuntingExWeb.QueryController do
  use JobHuntingExWeb, :controller

  def show(conn, %{"id" => id}) do
    case JobHuntingEx.Queries.get_listings(id) do
      [] ->
        render(conn, :show, listings: [])

      listings ->
        render(conn, :show, listings: listings)
    end
  end
end
