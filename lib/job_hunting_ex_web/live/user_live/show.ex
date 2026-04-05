defmodule JobHuntingExWeb.UserLive.Show do
  use JobHuntingExWeb, :live_view
  use Phoenix.Component

  require Logger

  alias Phoenix.LiveView.AsyncResult
  alias JobHuntingEx.Queries.UserQuery
  alias JobHuntingEx.Pdf
  alias JobHuntingEx.Error
  alias JobHuntingEx.Workers.ScheduledWorker

  @fake_queries [
    %{
      "id" => "100",
      "keyword" => "Elixir Developer",
      "location" => "San Jose, CA",
      "radius" => 25,
      "minimum_years_of_experience" => 2,
      "maximum_years_of_experience" => 8,
      "remote?" => true,
      "result_count" => 14,
      "last_run" => "Mar 24, 2026"
    },
    %{
      "id" => "101",
      "keyword" => "Software Engineer",
      "location" => "San Francisco, CA",
      "radius" => 10,
      "minimum_years_of_experience" => 1,
      "maximum_years_of_experience" => 5,
      "remote?" => false,
      "result_count" => 23,
      "last_run" => "Mar 24, 2026"
    },
    %{
      "id" => "102",
      "keyword" => "Backend Engineer",
      "location" => "Remote",
      "radius" => nil,
      "minimum_years_of_experience" => 3,
      "maximum_years_of_experience" => 10,
      "remote?" => true,
      "result_count" => 7,
      "last_run" => "Mar 23, 2026"
    }
  ]

  @impl true
  def mount(_params, _sessions, socket) do
    user_id = socket.assigns.current_scope.user.id
    queries = JobHuntingEx.Queries.get_user_queries_from_id(user_id)

    socket =
      socket
      |> assign(:form, to_form(UserQuery.changeset(%UserQuery{})))
      |> assign(:saved_queries, queries)
      |> assign(:async_queries, %{})
      |> allow_upload(:resume,
        accept: ~w(.pdf),
        max_entries: 1,
        auto_upload: true,
        progress: &handle_progress/3
      )

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
            Queries saved here will be run daily and you can come back here to check the results!
          </p>
        </div>

        <.form
          class="grid grid-cols-6 gap-x-3 gap-y-1"
          for={@form}
          id="search-form"
          phx-change="validate"
          phx-submit="save"
        >
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
          <div class="col-span-2 flex items-end">
            <label class={[
              "flex h-10 w-full min-w-0 flex-nowrap items-center justify-center gap-2 overflow-hidden px-4 text-sm font-medium leading-none rounded-lg transition-colors duration-150 border",
              if(resume_uploading?(@uploads.resume),
                do: "text-zinc-400 border-gray-200 cursor-wait",
                else: "text-zinc-500 border-gray-300 cursor-pointer"
              )
            ]}>
              <%= cond do %>
                <% resume_uploading?(@uploads.resume) -> %>
                  <div class="size-4 shrink-0 rounded-full border-2 border-gray-200 border-t-gray-600 animate-spin" />
                  <span class="shrink-0 whitespace-nowrap">Uploading...</span>
                <% not Enum.empty?(@uploads.resume.entries) -> %>
                  <.icon name="hero-document-check" class="size-5 shrink-0 text-emerald-500" />
                  <span class="shrink-0 whitespace-nowrap">Resume</span>
                <% true -> %>
                  <.icon name="hero-document-arrow-up" class="size-5 shrink-0" />
                  <span class="shrink-0 whitespace-nowrap">Upload Resume (PDF)</span>
              <% end %>
              <.live_file_input upload={@uploads.resume} class="hidden" />
            </label>
          </div>
          <div class="col-span-2 flex items-end">
            <.button
              variant="primary"
              class="w-full text-sm"
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
              <.card
                query={query}
                async_status={Map.get(assigns.async_queries, query["id"], AsyncResult.ok(:ready))}
              />
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
        <.async_result :let={_async_state} assign={@async_status}>
          <:loading>
            <div class="relative">
              <div class="invisible pointer-events-none select-none" aria-hidden="true">
                <.card_query_body query={@query} />
              </div>
              <div class="absolute inset-0 flex items-center justify-center bg-white/90">
                <div class="h-8 w-8 animate-spin rounded-full border-2 border-gray-200 border-t-gray-900" />
              </div>
            </div>
          </:loading>
          <:failed>
            <p>Failure</p>
          </:failed>
          <.card_query_body query={@query} />
        </.async_result>
      </div>
    </div>
    """
  end

  defp card_query_body(assigns) do
    ~H"""
    <div class="flex items-start justify-between">
      <h3 class="text-base font-semibold text-gray-900">{@query["keyword"]}</h3>
      <button class="text-gray-400 hover:text-red-500 cursor-pointer" title="Delete query">
        <.icon name="hero-x-mark" class="h-4 w-4" />
      </button>
    </div>
    <p class="mt-1 text-sm text-gray-600">
      {@query["location"]}
      <span :if={@query["radius"]}> &middot;{to_string(@query["radius"])} mi</span>
    </p>
    <div class="mt-2 flex flex-wrap gap-1.5">
      <span class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-700">
        {@query["minimum_years_of_experience"]}-{@query["maximum_years_of_experience"]} yrs exp
      </span>
      <span
        :if={@query["remote?"]}
        class="inline-flex items-center rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-700"
      >
        Including Remote
      </span>
    </div>
    <div class="mt-4 flex items-center justify-between border-t border-gray-100 pt-3">
      <div class="text-xs text-gray-500">
        <span>{@query["result_count"]} results</span>
        <span> &middot;{@query["last_run"]}</span>
      </div>
      <.button variant="primary" class="text-sm" navigate={~p"/query/fake-id"}>
        View Results
      </.button>
    </div>
    """
  end

  defp resume_uploading?(upload_config) do
    Enum.any?(upload_config.entries, fn entry ->
      entry.progress > 0 and not entry.done?
    end)
  end

  defp handle_progress(:resume, entry, socket) do
    if entry.done? do
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp upload_error_to_string(:too_large), do: "File is too large"
  defp upload_error_to_string(:not_accepted), do: "Invalid file type. Please upload a PDF"
  defp upload_error_to_string(:too_many_files), do: "Too many files selected"
  defp upload_error_to_string(_), do: "Upload failed"

  @impl true
  def handle_event("validate", %{"user_query" => query_params}, socket) do
    changeset =
      UserQuery.changeset(%UserQuery{}, query_params)

    socket = assign(socket, form: to_form(changeset))

    {socket, errors} =
      Enum.reduce(socket.assigns.uploads.resume.entries, {socket, []}, fn entry, {sock, errs} ->
        entry_errors = upload_errors(sock.assigns.uploads.resume, entry)

        if entry_errors != [] do
          {cancel_upload(sock, :resume, entry.ref),
           errs ++ Enum.map(entry_errors, &upload_error_to_string/1)}
        else
          {sock, errs}
        end
      end)

    upload_config_errors = upload_errors(socket.assigns.uploads.resume)

    all_errors =
      errors ++ Enum.map(upload_config_errors, &upload_error_to_string/1)

    socket =
      if all_errors != [] do
        put_flash(socket, :error, Enum.join(Enum.uniq(all_errors), ". "))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"user_query" => query_params}, socket) do
    user_query = query_params

    user_query =
      case user_query["remote?"] do
        "true" -> Map.put(user_query, "workplace_types", ["Hybrid", "On-Site", "Remote"])
        "false" -> Map.put(user_query, "workplace_types", ["Hybrid", "On-Site"])
      end

    user_id = socket.assigns.current_scope.user.id

    with :ok <- length_equal_to_one(socket.assigns.uploads.resume.entries),
         {:ok, resume_text} <- file_upload(socket),
         {:ok, user_query_id} <-
           JobHuntingEx.Queries.save_user_query(user_query, user_id, resume_text) do
      params = %{args: %{"user_query_id" => user_query_id, "user_id" => user_id}, attempt: 1}
      query_params = Map.put(query_params, "id", user_query_id)
      saved_queries = [query_params] ++ socket.assigns.saved_queries
      IO.inspect(socket.assigns.async_queries)

      socket =
        socket
        |> assign(:saved_queries, saved_queries)
        |> assign(
          :async_queries,
          Map.put(socket.assigns.async_queries, user_query_id, AsyncResult.loading())
        )
        |> start_async({:save, user_query_id}, fn -> ScheduledWorker.perform(params) end)

      {:noreply, socket}
    else
      {:error, reason} ->
        Logger.error(Error.normalize_error(reason))
        {:noreply, socket}
    end
  end

  defp length_equal_to_one(list) do
    case length(list) do
      1 -> :ok
      _ -> {:error, "User Query resume uploads list is empty"}
    end
  end

  defp file_upload(socket) do
    file_upload =
      consume_uploaded_entries(socket, :resume, fn %{path: path}, _entry ->
        case Pdf.extract_text(path) do
          {:ok, text} -> {:ok, text}
          {:error, reason} -> {:ok, {:error, reason}}
        end
      end)

    case file_upload do
      [{:error, reason}] ->
        Logger.error(reason)

        {:error, reason}

      [text] ->
        {:ok, text}

      [] ->
        {:error, "No text"}
    end
  end

  @impl true
  def handle_async({:save, user_query_id}, {:ok, :ok}, socket) do
    async_queries =
      socket.assigns.async_queries
      |> Map.put(user_query_id, AsyncResult.ok(:ready))

    socket =
      socket
      |> assign(:async_queries, async_queries)

    {:noreply, socket}
  end

  @impl true
  def handle_async({:save, user_query_id}, {:exit, reason}, socket) do
    Logger.error(inspect(reason))

    result = Map.get(socket.assigns.async_queries, user_query_id)

    async_queries =
      socket.assigns.async_queries
      |> Map.put(user_query_id, AsyncResult.failed(result, reason))

    socket =
      socket
      |> assign(:async_queries, async_queries)

    {:noreply, socket}
  end
end
