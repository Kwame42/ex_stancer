defmodule Stancer.OpenAPILoader do
  @moduledoc """
  Loads the Stancer OpenAPI specification with intelligent fallback.

  1. Tries to download from Stancer
  2. Falls back to cached version in priv/openapi.json
  3. Logs version info when using cached version
  """

  require Logger

  @openapi_url "https://docs.stancer.com/api/openapi.json"

  def load_spec do
    # Try to download first
    case download_spec() do
      {:ok, spec} ->
        Logger.info("Loaded Stancer OpenAPI spec from remote (#{get_version_info(spec)})")
        {:ok, spec}

      :error ->
        # Fallback to cached version
        case load_cached_spec() do
          {:ok, spec} ->
            version = get_version_info(spec)
            Logger.warning(
              "Failed to download OpenAPI spec. Using cached version: #{version}. " <>
              "Please ensure network connectivity for the latest API spec."
            )
            {:ok, spec}

          :error ->
            {:error, "No OpenAPI spec available (network error and no cached version)"}
        end
    end
  end

  def load_spec! do
    case load_spec() do
      {:ok, spec} -> spec
      {:error, reason} -> raise reason
    end
  end

  defp download_spec do
    with :ok <- Application.ensure_started(:req),
         {:ok, response} <- Req.get(@openapi_url) do
      spec =
        case response.body do
          body when is_map(body) -> body
          body when is_binary(body) -> Jason.decode!(body)
          _ -> nil
        end

      if spec do
        # Cache it for future use
        cache_spec(spec)
        {:ok, spec}
      else
        :error
      end
    else
      _ -> :error
    end
  end

  defp load_cached_spec do
    priv_path = Application.app_dir(:stancer, "priv/openapi.json")

    case File.read(priv_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, spec} -> {:ok, spec}
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp cache_spec(spec) do
    priv_path = Application.app_dir(:stancer, "priv/openapi.json")
    File.write!(priv_path, Jason.encode!(spec, pretty: true))
  end

  defp get_version_info(spec) do
    info = Map.get(spec, "info", %{})
    version = Map.get(info, "version", "unknown")

    # Try to get timestamp if available
    timestamp =
      Map.get(info, "x-updated-at") ||
      Map.get(info, "x-timestamp") ||
      Map.get(info, "x-date") ||
      ""

    if timestamp != "" do
      "v#{version} (#{timestamp})"
    else
      "v#{version}"
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
