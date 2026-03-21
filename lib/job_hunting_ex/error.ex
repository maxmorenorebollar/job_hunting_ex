defmodule JobHuntingEx.Error do
  @moduledoc """
  Provides helper functions to normalize errors
  """

  def normalize_error(err) when is_binary(err) do
    err
  end

  def normalize_error(err) when is_exception(err) do
    Exception.message(err)
  end

  def normalize_error(%Ecto.Changeset{} = changeset) do
    errors_as_map =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    errors_as_map
    |> Map.to_list()
    |> Enum.reduce("", fn {error, message}, acc -> acc <> "#{error} #{message}. " end)
  end

  def normalize_error(err) do
    inspect(err)
  end
end
