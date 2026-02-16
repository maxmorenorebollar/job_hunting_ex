defmodule JobHuntingExWeb.PageController do
  use JobHuntingExWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
