defmodule JobHuntingEx.Queries.Pdf do
  @moduledoc """
  Provides function to extract text from pdf
  """

  @spec extract_text(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def extract_text(pdf_path) do
    args = [pdf_path, "-"]

    case System.cmd("pdftotext", args) do
      {:ok, text} ->
        String.replace(text, "\n", " ")

      {error, exit_status} ->
        {:error, "pdftotext failed with exit_status #{exit_status} and reason: #{error}"}
    end
  end
end
