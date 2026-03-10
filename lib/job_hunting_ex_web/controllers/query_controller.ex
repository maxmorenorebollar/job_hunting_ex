defmodule JobHuntingExWeb.QueryController do
  use JobHuntingExWeb, :controller

  def show(conn, params) do
    IO.inspect(params)
    %{"id" => id} = params

    case JobHuntingEx.Queries.get_listings(id) do
      [] -> render(conn, :show, listings: [])
      listings -> render(conn, :show, listings: listings)
    end
  end
end
