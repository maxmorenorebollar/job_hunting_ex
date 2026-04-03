defmodule JobHuntingEx.Repo.Migrations.AddUniqueIndexUserQueriesSavedSearch do
  use Ecto.Migration

  def change do
    create unique_index(
             :user_queries,
             [
               :user_id,
               :keyword,
               :location,
               :radius,
               :minimum_years_of_experience,
               :maximum_years_of_experience,
               :remote?
             ],
             name: :user_queries_user_saved_search_unique
           )
  end
end
