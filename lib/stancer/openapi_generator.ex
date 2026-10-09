defmodule Stancer.OpenAPIGenerator do
  @moduledoc """
  Generates API functions dynamically from OpenAPI specification.
  """

  require Logger

  def generate_api_functions(spec) do
    endpoints = Stancer.OpenAPILoader.extract_endpoints(spec)

    Logger.info("Generating #{Enum.count(endpoints)} API functions from OpenAPI spec")

    Enum.flat_map(endpoints, &generate_function_ast/1)
  end

  defp generate_function_ast(endpoint) do
    method = endpoint["method"]
    path = endpoint["path"]
    operation_id = endpoint["operation_id"]
    description = endpoint["description"]
    parameters = endpoint["parameters"]
    request_body = endpoint["request_body"]

    case method do
      "GET" -> generate_get_function_ast(operation_id, path, description, parameters)
      "POST" -> generate_post_function_ast(operation_id, path, description, parameters, request_body)
      "PUT" -> generate_put_function_ast(operation_id, path, description, parameters, request_body)
      "DELETE" -> generate_delete_function_ast(operation_id, path, description, parameters)
      "PATCH" -> generate_patch_function_ast(operation_id, path, description, parameters, request_body)
      _ -> []
    end
  end

  defp generate_get_function_ast(operation_id, path, description, parameters) do
    path_params = Enum.filter(parameters, &(Map.get(&1, "in") == "path"))

    function_name = String.to_atom(operation_id)
    doc = build_doc(description, operation_id, "GET", path, parameters, nil)

    if Enum.empty?(path_params) do
      [
        quote do
          @doc unquote(doc)
          @spec unquote(function_name)() :: {:ok, map()} | {:error, term()}
          def unquote(function_name)() do
            Stancer.request(:get, unquote(path))
          end
        end
      ]
    else
      # With path parameters - not implemented for simplicity
      []
    end
  end

  defp generate_post_function_ast(operation_id, path, description, parameters, request_body) do
    path_params = Enum.filter(parameters, &(Map.get(&1, "in") == "path"))

    function_name = String.to_atom(operation_id)
    doc = build_doc(description, operation_id, "POST", path, parameters, request_body)

    if Enum.empty?(path_params) and request_body do
      [
        quote do
          @doc unquote(doc)
          @spec unquote(function_name)(map()) :: {:ok, map()} | {:error, term()}
          def unquote(function_name)(data) when is_map(data) do
            Stancer.request(:post, unquote(path), data)
          end
        end
      ]
    else
      []
    end
  end

  defp generate_put_function_ast(operation_id, path, description, parameters, request_body) do
    path_params = Enum.filter(parameters, &(Map.get(&1, "in") == "path"))

    function_name = String.to_atom(operation_id)
    doc = build_doc(description, operation_id, "PUT", path, parameters, request_body)

    if Enum.empty?(path_params) and request_body do
      [
        quote do
          @doc unquote(doc)
          @spec unquote(function_name)(map()) :: {:ok, map()} | {:error, term()}
          def unquote(function_name)(data) when is_map(data) do
            Stancer.request(:put, unquote(path), data)
          end
        end
      ]
    else
      []
    end
  end

  defp generate_delete_function_ast(operation_id, path, description, parameters) do
    path_params = Enum.filter(parameters, &(Map.get(&1, "in") == "path"))

    function_name = String.to_atom(operation_id)
    doc = build_doc(description, operation_id, "DELETE", path, parameters, nil)

    if Enum.empty?(path_params) do
      [
        quote do
          @doc unquote(doc)
          @spec unquote(function_name)() :: {:ok, map()} | {:error, term()}
          def unquote(function_name)() do
            Stancer.request(:delete, unquote(path))
          end
        end
      ]
    else
      []
    end
  end

  defp generate_patch_function_ast(operation_id, path, description, parameters, request_body) do
    path_params = Enum.filter(parameters, &(Map.get(&1, "in") == "path"))

    function_name = String.to_atom(operation_id)
    doc = build_doc(description, operation_id, "PATCH", path, parameters, request_body)

    if Enum.empty?(path_params) and request_body do
      [
        quote do
          @doc unquote(doc)
          @spec unquote(function_name)(map()) :: {:ok, map()} | {:error, term()}
          def unquote(function_name)(data) when is_map(data) do
            Stancer.request(:patch, unquote(path), data)
          end
        end
      ]
    else
      []
    end
  end

  defp build_doc(description, operation_id, method, path, parameters, request_body) do
    doc_parts = [
      "#{method} #{path}",
      "",
      description || operation_id
    ]

    doc_parts =
      if Enum.any?(parameters) do
        doc_parts ++
          [
            "",
            "Parameters:",
            format_parameters(parameters)
          ]
      else
        doc_parts
      end

    doc_parts =
      if request_body do
        doc_parts ++ ["", "Request body: JSON object with request data"]
      else
        doc_parts
      end

    doc_parts = doc_parts ++ ["", "Returns: `{:ok, response_data}` on success or `{:error, reason}` on failure"]

    Enum.join(doc_parts, "\n")
  end

  defp format_parameters(parameters) do
    parameters
    |> Enum.map(fn param ->
      name = Map.get(param, "name", "")
      location = Map.get(param, "in", "")
      description = Map.get(param, "description", "")
      required = Map.get(param, "required", false)

      "- `#{name}` (#{location})#{if required, do: " **required**", else: ""}: #{description}"
    end)
    |> Enum.join("\n")
  end
end
