defmodule JobHuntingExWeb.QueryLive.New do
  use JobHuntingExWeb, :live_view
  alias JobHuntingEx.Queries.Query
  alias JobHuntingEx.Queries.Data

  def mount(_params, _session, socket) do
    changeset = Query.changeset(%Query{})

    socket =
      socket
      |> assign(form: to_form(changeset))

    {:ok, socket}
  end

  def handle_event("validate", %{"query" => query_params}, socket) do
    changeset =
      Query.changeset(%Query{}, query_params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(form: to_form(changeset))

    {:noreply, socket}
  end

  def handle_event("search", %{"query" => query_params}, socket) do
    IO.inspect(query_params)
    liveview_pid = self()

    Task.start(fn ->
      case Data.process(query_params) do
        {:ok, _result} -> send(liveview_pid, "done")
      end
    end)

    {:noreply, socket}
  end

  def handle_info("done", socket) do
    IO.puts("finished!")
    {:noreply, socket |> put_flash(:info, "query succeeded")}
  end

  def handle_info("failed", socket) do
    {:noreply, socket |> put_flash(:info, "query failed")}
  end
end
