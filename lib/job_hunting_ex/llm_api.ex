defmodule JobHuntingEx.LlmApi do
  @moduledoc """
  Provide function to interact with groq api for llm data processing
  """

  alias JobHuntingEx.Error

  defp http_client() do
    Application.get_env(:job_hunting_ex, :http_client)
  end

  @spec fetch_job_data(String.t()) :: {:ok, map()} | {:error, String.t()}
  def fetch_job_data(job_description) do
    body = %{
      "model" => "openai/gpt-oss-20b",
      "messages" => [
        %{
          "role" => "user",
          "content" =>
            "You are given a job listing. Determine what the minimum number of years of experience that would qualify someone for this role. Often you will see jobs requiring either a masters and some number of years of experience or a bachelors with more required years of experience. Take the years of expererience as if the applicant doesn't have a masters. You are allowed to make an educated guess on the years of experience based on the title. Overall, you should return the years of experience as a whole number number rounding up. If it says senior then you can infer the required years of experience is 5 etc. Return the answer or -1 if not found. As well, determine what are the top 5 most needed skills for this role are and limit them to 1 or two words. If there are less than 5 skills needed that's okay. Also provide a one sentence summary of the description. Pay close attention to what you would actually be working on in the job like particular teams. Here is the listing: #{job_description}"
        }
      ],
      "response_format" => %{
        "type" => "json_schema",
        "json_schema" => %{
          "name" => "listing",
          "strict" => true,
          "schema" => %{
            "type" => "object",
            "properties" => %{
              "min_years_of_experience" => %{
                "type" => "number"
              },
              "skills" => %{
                "type" => "array",
                "items" => %{"type" => "string"}
              },
              "summary" => %{
                "type" => "string"
              }
            },
            "required" => ["min_years_of_experience", "skills", "summary"],
            "additionalProperties" => false
          }
        }
      }
    }

    request =
      http_client().post(
        url: "https://api.groq.com/openai/v1/chat/completions",
        auth: {:bearer, "#{System.get_env("GROQ_API_KEY")}"},
        json: body
      )

    case request do
      {:ok, res} ->
        json_content =
          res.body
          |> Map.get("choices")
          |> List.first()
          |> Map.get("message")
          |> Map.get("content")
          |> Jason.decode()

        # TODO: many points of failure here. Need to handle error and exception being thrown
        case json_content do
          {:ok, %{"min_years_of_experience" => -1}} ->
            {:error, "Minimum years of experience could not be extracted"}

          {:ok,
           %{
             "min_years_of_experience" => years,
             "skills" => skills,
             "summary" => summary
           }} ->
            {:ok,
             %{
               "min_years_of_experience" => years,
               "skills" => skills,
               "summary" => summary
             }}
        end

      {:error, err} ->
        {:error, Error.normalize_error(err)}
    end
  end
end
