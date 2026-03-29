defmodule JobHuntingExWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use JobHuntingExWeb, :html

  alias Phoenix.LiveView.JS

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <header class="sticky top-0 z-50 bg-white border-b border-gray-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center h-16">
            <div class="flex-shrink-0">
              <.link
                navigate={~p"/"}
                class="inline-flex items-center gap-2 text-xl font-semibold text-gray-900 tracking-tight hover:text-gray-700 transition-colors"
              >
                <.icon name="hero-magnifying-glass" class="w-5 h-5" /> Job Lens
              </.link>
            </div>
            <.hamburger_button />
            <.top_nav_content current_scope={@current_scope} />
          </div>
        </div>
        <.hamburger_panel current_scope={@current_scope} />
      </header>

      <main class="flex-1 px-4 py-20 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-2xl space-y-4">
          {render_slot(@inner_block)}
        </div>
      </main>
      <footer class="border-t border-gray-900 bg-gray-900 shadow-[0px_4px_12px_0px_rgba(0,0,0,0.15)]">
        <div class="mx-auto max-w-7xl px-4 py-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-end">
            <nav class="flex items-center gap-6">
              <.link
                navigate={~p"/about"}
                class="text-sm font-medium text-gray-400 hover:text-white transition-colors"
              >
                About
              </.link>
            </nav>
          </div>
        </div>
      </footer>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  defp top_nav_content(assigns) do
    ~H"""
    <nav class="hidden md:flex md:items-center md:space-x-8">
      <.link
        navigate={~p"/"}
        class="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
      >
        Home
      </.link>
      <%= if @current_scope do %>
        <span class="text-sm font-medium text-gray-600">
          {@current_scope.user.email}
        </span>
        <.link
          navigate={~p"/users/queries"}
          class="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
        >
          Queries
        </.link>
        <.link
          navigate={~p"/users/settings"}
          class="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
        >
          Settings
        </.link>
        <.link
          href={~p"/users/log-out"}
          method="delete"
          class="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
        >
          Log out
        </.link>
      <% else %>
        <.link
          navigate={~p"/users/register"}
          class="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
        >
          Register
        </.link>
        <.link
          navigate={~p"/users/log-in"}
          class="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
        >
          Log in
        </.link>
      <% end %>
    </nav>
    """
  end

  defp hamburger_button(assigns) do
    ~H"""
    <div class="md:hidden">
      <button phx-click={show_hamburger()} class="p-2 rounded hover:bg-gray-100">
        <.icon name="hero-bars-3" class="h-6 w-6" />
      </button>
    </div>
    """
  end

  defp hamburger_panel(assigns) do
    ~H"""
    <div id="hamburger-container" class="hidden relative z-50">
      <div id="hamburger-backdrop" class="fixed inset-0 bg-zinc-50/90 transition-opacity"></div>
      <nav
        id="hamburger-content"
        class="fixed top-0 left-0 bottom-0 flex flex-col grow justify-between w-3/4 max-w-sm py-6 bg-white border-r overflow-y-auto"
      >
        <div>
          <div class="flex items-center mb-4 place-content-between mx-4 border-b border-gray-200 pb-4">
            <.link
              navigate={~p"/"}
              class="inline-flex items-center gap-2 text-xl font-semibold text-gray-900 tracking-tight"
            >
              <.icon name="hero-magnifying-glass" class="w-5 h-5" /> Job Lens
            </.link>
            <button phx-click={hide_hamburger()} class="p-2 rounded hover:bg-gray-100">
              <.icon name="hero-x-mark" class="h-6 w-6" />
            </button>
          </div>
          <ul>
            <li class="block px-6 py-2 text-sm font-semibold hover:bg-gray-200">
              <.link navigate={~p"/"}>Home</.link>
            </li>
            <%= if @current_scope do %>
              <li class="block px-6 py-2 text-sm font-semibold hover:bg-gray-200">
                <.link navigate={~p"/users/queries"}>Queries</.link>
              </li>
              <li class="block px-6 py-2 text-sm font-semibold hover:bg-gray-200">
                <.link navigate={~p"/users/settings"}>Settings</.link>
              </li>
              <li class="block px-6 py-2 text-sm font-semibold hover:bg-gray-200">
                <.link href={~p"/users/log-out"} method="delete">Log out</.link>
              </li>
            <% else %>
              <li class="block px-6 py-2 text-sm font-semibold hover:bg-gray-200">
                <.link navigate={~p"/users/register"}>Register</.link>
              </li>
              <li class="block px-6 py-2 text-sm font-semibold hover:bg-gray-200">
                <.link navigate={~p"/users/log-in"}>Log in</.link>
              </li>
            <% end %>
          </ul>
        </div>
      </nav>
    </div>
    """
  end

  defp show_hamburger(js \\ %JS{}) do
    js
    |> JS.show(
      to: "#hamburger-content",
      transition:
        {"transition-all transform ease-in-out duration-300", "-translate-x-3/4", "translate-x-0"},
      time: 300,
      display: "flex"
    )
    |> JS.show(
      to: "#hamburger-backdrop",
      transition:
        {"transition-all transform ease-in-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(to: "#hamburger-container", time: 300)
    |> JS.add_class("overflow-hidden", to: "body")
  end

  defp hide_hamburger(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#hamburger-backdrop",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "#hamburger-content",
      transition:
        {"transition-all transform ease-in duration-200", "translate-x-0", "-translate-x-3/4"}
    )
    |> JS.hide(to: "#hamburger-container", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
