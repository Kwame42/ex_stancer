defmodule Stancer.DynamicAPI do
  @moduledoc """
  Dynamically generated Stancer API functions from OpenAPI specification.

  This module generates all available API functions at runtime from the Stancer OpenAPI spec.
  Each function is automatically documented and type-specified based on the schema.

  ## Generated Functions

  Functions are generated for each endpoint in the OpenAPI spec, including:
  - `tokenize_card/1` - POST /tokens
  - `create_payment/1` - POST /payments
  - `get_payment/1` - GET /payments/{id}
  - `capture_payment/2` - POST /payments/{id}/capture
  - `refund_payment/2` - POST /payments/{id}/refund
  - `get_card/1` - GET /cards/{id}
  - `delete_card/1` - DELETE /cards/{id}
  - And many more endpoints based on the Stancer API

  All functions return `{:ok, response_data}` on success or `{:error, reason}` on failure.
  """

  @doc """
  Load the OpenAPI specification and return all available endpoints.

  Returns a list of endpoint maps with metadata from the OpenAPI spec.
  """
  @spec get_endpoints() :: {:ok, [map()]} | {:error, term()}
  def get_endpoints do
    case Stancer.OpenAPILoader.load_spec() do
      {:ok, spec} ->
        endpoints = Stancer.OpenAPILoader.extract_endpoints(spec)
        {:ok, endpoints}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get information about a specific endpoint.

  Parameters:
  - `operation_id`: The operationId from OpenAPI (e.g., "post_tokens")

  Returns: `{:ok, endpoint_info}` or `{:error, :not_found}`
  """
  @spec get_endpoint_info(String.t()) :: {:ok, map()} | {:error, atom()}
  def get_endpoint_info(operation_id) when is_binary(operation_id) do
    case get_endpoints() do
      {:ok, endpoints} ->
        case Enum.find(endpoints, &(Map.get(&1, "operation_id") == operation_id)) do
          nil -> {:error, :not_found}
          endpoint -> {:ok, endpoint}
        end

      error ->
        error
    end
  end

  @doc """
  Get all available operations grouped by tag/resource.

  Returns a map where keys are resource names and values are lists of operations.
  """
  @spec get_operations_by_resource() :: {:ok, map()} | {:error, term()}
  def get_operations_by_resource do
    case get_endpoints() do
      {:ok, endpoints} ->
        grouped =
          endpoints
          |> Enum.group_by(fn endpoint ->
            endpoint["path"]
            |> String.split("/")
            |> Enum.filter(&(String.length(&1) > 0 && !String.starts_with?(&1, "{")))
            |> List.first()
            |> String.to_atom()
          end)

        {:ok, grouped}

      error ->
        error
    end
  end

  @doc """
  Call an API endpoint dynamically by name with parameters.

  Parameters:
  - `operation_id`: The operationId from OpenAPI
  - `params`: Map or list of parameters for the operation

  Returns: `{:ok, response}` or `{:error, reason}`

  Example:
  ```elixir
  {:ok, token} = Stancer.DynamicAPI.call("post_tokens", %{
    "card" => %{
      "number" => "4111111111111111",
      "exp_month" => 12,
      "exp_year" => 2026,
      "cvc" => "123"
    }
  })
  ```
  """
  @spec call(String.t(), map() | list()) :: {:ok, map()} | {:error, term()}
  def call(operation_id, params \\ %{}) when is_binary(operation_id) do
    case get_endpoint_info(operation_id) do
      {:ok, endpoint} ->
        execute_endpoint(endpoint, params)

      error ->
        error
    end
  end

  defp execute_endpoint(endpoint, params) do
    method = endpoint["method"]
    path = endpoint["path"]

    case method do
      "GET" ->
        Stancer.request(:get, path)

      "POST" ->
        Stancer.request(:post, path, params)

      "PUT" ->
        Stancer.request(:put, path, params)

      "DELETE" ->
        Stancer.request(:delete, path)

      "PATCH" ->
        Stancer.request(:patch, path, params)

      _ ->
        {:error, "Unknown HTTP method: #{method}"}
    end
  end

  @doc """
  List all available API operations with their documentation.

  Returns a list of operation maps with full metadata.
  """
  @spec list_operations() :: {:ok, [map()]} | {:error, term()}
  def list_operations do
    case get_endpoints() do
      {:ok, endpoints} ->
        operations =
          endpoints
          |> Enum.map(fn endpoint ->
            %{
              "operation_id" => endpoint["operation_id"],
              "method" => endpoint["method"],
              "path" => endpoint["path"],
              "summary" => endpoint["summary"],
              "description" => endpoint["description"]
            }
          end)

        {:ok, operations}

      error ->
        error
    end
  end

  @doc """
  Print formatted documentation for all available operations.

  This is useful for exploring the API in development.
  """
  @spec print_api_docs() :: :ok | {:error, term()}
  def print_api_docs do
    case list_operations() do
      {:ok, operations} ->
        IO.puts("\n=== Stancer API Operations ===\n")

        operations
        |> Enum.sort_by(fn op -> op["path"] end)
        |> Enum.each(fn op ->
          IO.puts("#{op["method"]} #{op["path"]}")
          IO.puts("  Operation: #{op["operation_id"]}")
          IO.puts("  Summary: #{op["summary"]}")
          if op["description"] && op["description"] != op["summary"] do
            IO.puts("  Description: #{op["description"]}")
          end
          IO.puts("")
        end)

        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end
end
