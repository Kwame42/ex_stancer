defmodule Stancer.OpenAPILoader do
  @moduledoc """
  Loads and caches the Stancer OpenAPI specification.
  """

  @openapi_url "https://docs.stancer.com/api/openapi.json"

  def load_spec do
    with :ok <- Application.ensure_started(:req),
         {:ok, response} <- Req.get(@openapi_url) do
      spec =
        case response.body do
          body when is_map(body) -> body
          body when is_binary(body) -> Jason.decode!(body)
          _ -> raise "Invalid response body type"
        end

      {:ok, spec}
    else
      {:error, reason} ->
        {:error, "Failed to load OpenAPI spec: #{inspect(reason)}"}

      error ->
        {:error, "Unexpected error loading OpenAPI spec: #{inspect(error)}"}
    end
  end

  def load_spec! do
    case load_spec() do
      {:ok, spec} -> spec
      {:error, reason} -> raise reason
    end
  end

  def extract_endpoints(spec) do
    paths = Map.get(spec, "paths", %{})

    Enum.flat_map(paths, fn {path, methods} ->
      Enum.flat_map(methods, fn {method, details} ->
        if method in ["get", "post", "put", "delete", "patch"] do
          [build_endpoint(String.upcase(method), path, details)]
        else
          []
        end
      end)
    end)
  end

  defp build_endpoint(method, path, details) do
    operation_id = Map.get(details, "operationId", generate_operation_id(method, path))
    summary = Map.get(details, "summary", "")
    description = Map.get(details, "description", summary)
    parameters = Map.get(details, "parameters", [])
    request_body = Map.get(details, "requestBody", nil)
    responses = Map.get(details, "responses", %{})

    %{
      "method" => method,
      "path" => path,
      "operation_id" => operation_id,
      "summary" => summary,
      "description" => description,
      "parameters" => parameters,
      "request_body" => request_body,
      "responses" => responses
    }
  end

  defp generate_operation_id(method, path) do
    path
    |> String.split("/")
    |> Enum.filter(&(String.length(&1) > 0 && !String.starts_with?(&1, "{")))
    |> Enum.join("_")
    |> then(&"#{String.downcase(method)}_#{&1}")
  end

  def param_to_elixir_type(param) do
    schema = Map.get(param, "schema", %{})
    param_type = Map.get(schema, "type", "string")

    case param_type do
      "string" -> :string
      "integer" -> :integer
      "number" -> :float
      "boolean" -> :boolean
      "array" -> :list
      "object" -> :map
      _ -> :term
    end
  end
end
