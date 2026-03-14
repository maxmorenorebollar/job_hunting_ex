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

  def normalize_error(err) do
    inspect(err)
  end
end
