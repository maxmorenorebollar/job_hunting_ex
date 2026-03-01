defmodule JobHuntingEx.Queries.Pdf do
  def extract_text(pdf_path) do
    IO.inspect(pdf_path)
    args = [pdf_path, "-"]

    with {text, 0} <- System.cmd("pdftotext", args) do
      {:ok, String.replace(text, "\n", " ")}
    else
      {error, exit_status} ->
        {:error, "pdftotext failed with exit_status #{exit_status} and reason: #{error}"}
    end
  end
end
