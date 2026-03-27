defmodule JobHuntingExWeb.UserLive.Show do
  use JobHuntingExWeb, :live_view
  use Phoenix.Component

  alias JobHuntingEx.Queries.Query

  @fake_queries [
    %{
      keyword: "Elixir Developer",
      location: "San Jose, CA",
      radius: 25,
      min_exp: 2,
      max_exp: 8,
      remote: true,
      result_count: 14,
      last_run: "Mar 24, 2026"
    },
    %{
      keyword: "Software Engineer",
      location: "San Francisco, CA",
      radius: 10,
      min_exp: 1,
      max_exp: 5,
      remote: false,
      result_count: 23,
      last_run: "Mar 24, 2026"
    },
    %{
      keyword: "Backend Engineer",
      location: "Remote",
      radius: nil,
      min_exp: 3,
      max_exp: 10,
      remote: true,
      result_count: 7,
      last_run: "Mar 23, 2026"
    }
  ]

  @impl true
  def mount(_params, _sessions, socket) do
    socket =
      socket
      |> assign(:form, to_form(Query.changeset(%Query{})))
      |> assign(:saved_queries, @fake_queries)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <div>
          <h1 class="text-xl font-semibold">Saved Queries</h1>
          <p class="mt-1 text-sm text-gray-600">
            Queries saved here will be run daily and the top 20 jobs across all queries will be emailed to you every morning!
          </p>
        </div>

        <.form class="grid grid-cols-6 gap-x-3 gap-y-1" for={@form} id="search-form" phx-submit="save">
          <div class="col-span-3">
            <.input
              field={@form[:keyword]}
              type="text"
              label="Keyword"
              placeholder="e.g. Elixir Developer, Software Engineer"
            />
          </div>
          <div class="col-span-2">
            <.input
              field={@form[:location]}
              type="text"
              label="Location"
              placeholder="e.g. San Jose, CA"
            />
          </div>
          <div class="col-span-1">
            <.input
              field={@form[:radius]}
              type="text"
              label="Radius (mi)"
              placeholder="e.g. 10"
            />
          </div>
          <div class="col-span-2">
            <.input
              field={@form[:minimum_years_of_experience]}
              type="text"
              label="Min. Exp. (years)"
              placeholder="e.g. 1"
            />
          </div>
          <div class="col-span-2">
            <.input
              field={@form[:maximum_years_of_experience]}
              type="text"
              label="Max. Exp. (years)"
              placeholder="e.g. 15"
            />
          </div>
          <div class="col-span-2 flex items-end">
            <.input
              field={@form[:remote?]}
              type="checkbox"
              label="Include remote jobs"
            />
          </div>
          <div class="col-span-2">
            <.button
              variant="primary"
              class="text-sm"
              phx-disable-with="Saving..."
            >
              Save Query
            </.button>
          </div>
        </.form>

        <div class="space-y-3">
          <h2 class="text-lg font-semibold">Your Queries</h2>
          <div class="grid gap-4 grid-cols-1">
            <%= for query <- @saved_queries do %>
              <.card query={query} />
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp card(assigns) do
    ~H"""
    <div class="flex flex-col justify-between rounded-lg border border-gray-200 bg-white p-4 shadow-sm">
      <div>
        <div class="flex items-start justify-between">
          <h3 class="text-base font-semibold text-gray-900">{@query.keyword}</h3>
          <button class="text-gray-400 hover:text-red-500 cursor-pointer" title="Delete query">
            <.icon name="hero-x-mark" class="h-4 w-4" />
          </button>
        </div>
        <p class="mt-1 text-sm text-gray-600">
          {@query.location}
          <span :if={@query.radius}> &middot;        {to_string(@query.radius)} mi</span>
        </p>
        <div class="mt-2 flex flex-wrap gap-1.5">
          <span class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-700">
            {@query.min_exp}-{@query.max_exp} yrs exp
          </span>
          <span
            :if={@query.remote}
            class="inline-flex items-center rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-700"
          >
            Remote
          </span>
        </div>
      </div>
      <div class="mt-4 flex items-center justify-between border-t border-gray-100 pt-3">
        <div class="text-xs text-gray-500">
          <span>{@query.result_count} results</span>
          <span> &middot;        {@query.last_run}</span>
        </div>
        <.button variant="primary" class="text-sm" navigate={~p"/query/fake-id"}>
          View Results
        </.button>
      </div>
    </div>
    """
  end
end
