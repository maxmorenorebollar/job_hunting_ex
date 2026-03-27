defmodule JobHuntingExWeb.QueryLive.Show do
  use JobHuntingExWeb, :live_view
  alias JobHuntingEx.Queries

  def mount(params, _session, socket) do
    pretty_query_id = params["id"]
    query_id = Queries.get_query_from_pretty_query_id(pretty_query_id)

    listings =
      case query_id do
        nil -> []
        query_id -> Queries.get_listings(query_id.id)
      end

    socket =
      socket
      |> assign(listings: listings)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div>
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-lg font-semibold text-gray-900">{length(@listings)} results</h2>
          <.link
            navigate="/"
            class="inline-flex items-center text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
          >
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-1" /> New search
          </.link>
        </div>

        <div class="divide-y divide-gray-100">
          <%= for listing <- @listings do %>
            <a
              href={listing.url}
              target="_blank"
              class="block py-4 first:pt-0 last:pb-0 group"
            >
              <div class="flex items-start justify-between gap-3 mb-2">
                <div class="min-w-0">
                  <p class="text-sm font-medium text-gray-900 group-hover:text-gray-600 transition-colors">
                    {listing.title}
                  </p>
                  <p class="text-sm text-gray-500 break-all">
                    {listing.company_name}
                  </p>
                </div>
                <.icon
                  name="hero-arrow-top-right-on-square"
                  class="w-4 h-4 text-gray-300 group-hover:text-gray-500 shrink-0 transition-colors"
                />
              </div>

              <p class="text-sm text-gray-500 leading-relaxed line-clamp-2 mb-3">
                {listing.summary}
              </p>

              <div class="flex flex-wrap items-center gap-1.5">
                <span class="inline-flex items-center gap-1 text-xs font-medium text-gray-700 bg-gray-100 px-2 py-0.5 rounded-md">
                  {listing.years_of_experience}+ yrs
                </span>
                <span
                  :for={skill <- Enum.take(listing.skills, 5)}
                  class="text-xs text-gray-500 bg-gray-50 border border-gray-200 px-2 py-0.5 rounded-md"
                >
                  {skill}
                </span>
                <span
                  :if={length(listing.skills) > 5}
                  class="text-xs text-gray-400"
                >
                  +{length(listing.skills) - 5} more
                </span>
              </div>
            </a>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
