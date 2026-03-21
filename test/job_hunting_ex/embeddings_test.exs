defmodule JobHuntingEx.EmbeddingsTest do
  use ExUnit.Case, async: true

  test "timeout" do
    Req.Test.stub(JobHuntingEx.Embeddings, fn conn ->
      Req.Test.transport_error(conn, :timeout)
    end)

    assert JobHuntingEx.Embeddings.fetch_embeddings([
             "document description 1",
             "document description 2"
           ]) == {:error, "timeout"}
  end

  test "malformed json body" do
    Req.Test.stub(JobHuntingEx.Embeddings, fn conn ->
      Req.Test.json(conn, %{
        "data" => [
          %{"embedding" => ["this should not be valid", "this should not be valid"]},
          %{"embedding" => ["this should not be valid 2", "this should not be valid 2"]}
        ]
      })
    end)

    assert JobHuntingEx.Embeddings.fetch_embeddings([
             "document description 1",
             "document description 2"
           ]) ==
             {:error, "Openrouter request body was malformed"}
  end

  test "missing data key" do
    Req.Test.stub(JobHuntingEx.Embeddings, fn conn ->
      Req.Test.json(conn, %{
        "information" => [
          %{"embedding" => [0.1, 0.2, 0.3]},
          %{"embedding" => [0.5, 0.9]}
        ]
      })
    end)

    assert JobHuntingEx.Embeddings.fetch_embeddings([
             "document description 1",
             "document description 2"
           ]) ==
             {:error, "Openrouter request body was malformed"}
  end

  test "valid body and type for single document" do
    Req.Test.stub(JobHuntingEx.Embeddings, fn conn ->
      Req.Test.json(conn, %{
        "data" => [
          %{"embedding" => [0.1, 0.2, 0.3]}
        ]
      })
    end)

    assert JobHuntingEx.Embeddings.fetch_embeddings("document description 1") ==
             {:ok, [0.1, 0.2, 0.3]}
  end
end
