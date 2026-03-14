defmodule JobHuntingEx.McpClient do
  @moduledoc """
  MCP client for communicating with external tool servers.
  """

  use Anubis.Client,
    name: "JobHuntingEx",
    version: "1.0.0",
    protocol_version: "2025-03-26"
end
