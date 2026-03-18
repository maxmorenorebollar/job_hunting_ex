defmodule JobHuntingEx.LlmApiTest do
  use ExUnit.Case, async: true

  test "timeout" do
    Req.Test.stub(JobHuntingEx.LlmApi, fn conn ->
      Req.Test.transport_error(conn, :timeout)
    end)

    assert JobHuntingEx.LlmApi.fetch_job_data("Some description") == {:error, "timeout"}
  end

  test "empty list being returned from groq in choices key" do
    Req.Test.stub(JobHuntingEx.LlmApi, fn conn ->
      Req.Test.json(conn, %{"choices" => []})
    end)

    assert JobHuntingEx.LlmApi.fetch_job_data("Some description") ==
             {:error, "Groq request body was malformed"}
  end

  test "request replies with error code" do
    Req.Test.stub(JobHuntingEx.LlmApi, fn conn ->
      conn
      |> Plug.Conn.put_status(400)
      |> Req.Test.json(%{"choices" => %{}})
    end)

    assert JobHuntingEx.LlmApi.fetch_job_data("") ==
             {:error, "Request failed with status code 400"}
  end

  test "invalid json from groq response" do
    Req.Test.stub(JobHuntingEx.LlmApi, fn conn ->
      Req.Test.json(conn, %{
        "choices" => [
          %{
            "message" => %{
              "content" => "not valid json"
            }
          }
        ]
      })
    end)

    assert JobHuntingEx.LlmApi.fetch_job_data("Some description") ==
             {:error, "unexpected byte at position 0: 0x6E (\"n\")"}
  end

  test "success" do
    encoded_content =
      "{\"min_years_of_experience\":3,\"skills\":[\"Elixir\",\"API\",\"Distributed Systems\",\"Testings\",\"C++\"],\"summary\":\"Seeking a software engineer with 3 years experience to work on an Elixir-based real-time data infrastructure project.\"}"

    expected = %JobHuntingEx.LlmApi.GroqResponse{
      min_years_of_experience: 3,
      skills: ["Elixir", "API", "Distributed Systems", "Testings", "C++"],
      summary:
        "Seeking a software engineer with 3 years experience to work on an Elixir-based real-time data infrastructure project."
    }

    Req.Test.stub(JobHuntingEx.LlmApi, fn conn ->
      Req.Test.json(conn, %{
        "choices" => [
          %{
            "message" => %{
              "content" => encoded_content
            }
          }
        ]
      })
    end)

    assert JobHuntingEx.LlmApi.fetch_job_data(
             "Seeking software engineer with 3 years of experience. Will be working on elixir project, and real time data infrustructure. Required Skills: Elixir, API, Distributed Systems, Testings, C++"
           ) ==
             {:ok, expected}
  end
end
