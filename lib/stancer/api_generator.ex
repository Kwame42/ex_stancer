defmodule Stancer.APIGenerator do
  @moduledoc """
  Generates API modules from OpenAPI specification.

  Creates a module hierarchy like:
  - Stancer.API.Customers
  - Stancer.API.Customers.list/0
  - Stancer.API.Customers.create/1
  - Stancer.API.Customers.get/1
  - Stancer.API.Customers.update/2
  - Stancer.API.Customers.delete/1

  All generated from the Stancer OpenAPI spec at compile time.
  """

  @doc """
  Parse OpenAPI spec and group endpoints by resource.

  Returns a map of resources to their endpoints.
  """
  def parse_resources_from_spec(spec) do
    spec
    |> Map.get("paths", %{})
    |> Enum.reduce(%{}, fn {path, methods}, acc ->
      resource = extract_resource(path)
      method_entry = extract_method_info(path, methods)

      if resource and method_entry do
        Map.update(acc, resource, [method_entry], &[method_entry | &1])
      else
        acc
      end
    end)
    |> Enum.map(fn {resource, endpoints} ->
      {resource, Enum.reverse(endpoints)}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Generate module definitions for all resources.

  Returns a list of module AST that can be quoted/unquoted.
  """
  def generate_resource_modules(spec) do
    resources = parse_resources_from_spec(spec)

    resources
    |> Enum.map(fn {resource_name, endpoints} ->
      generate_resource_module(resource_name, endpoints)
    end)
  end

  defp generate_resource_module(resource_name, endpoints) do
    module_name = "Stancer.API.#{Macro.camelize(resource_name)}" |> String.to_atom()

    doc = build_module_doc(resource_name, endpoints)

    # Group endpoints by action (list, create, get, update, delete)
    functions = generate_functions_for_resource(endpoints)

    quote do
      defmodule unquote(module_name) do
        @moduledoc unquote(doc)

        unquote_splicing(functions)
      end
    end
  end

  defp generate_functions_for_resource(endpoints) do
    endpoints
    |> Enum.group_by(&classify_endpoint/1)
    |> Enum.flat_map(fn {action, grouped_endpoints} ->
      Enum.map(grouped_endpoints, &generate_function(&1, action))
    end)
  end

  defp classify_endpoint(%{"method" => method, "path" => path}) do
    case {method, has_id_param?(path)} do
      {"GET", false} -> :list
      {"POST", false} -> :create
      {"GET", true} -> :get
      {"PUT", true} -> :update
      {"PATCH", true} -> :update
      {"DELETE", true} -> :delete
      _ -> :other
    end
  end

  defp has_id_param?(path) do
    String.contains?(path, ["{id}", "{customer_id}", "{payment_id}"])
  end

  defp generate_function(endpoint, action) do
    %{"path" => path, "description" => description} = endpoint
    method = Map.get(endpoint, "method", "")
    doc = build_function_doc(action, method, path, description)

    case action do
      :list ->
        quote do
          @doc unquote(doc)
          @spec list() :: {:ok, map()} | {:error, term()}
          def list do
            Stancer.request(:get, unquote(path))
          end
        end

      :create ->
        quote do
          @doc unquote(doc)
          @spec create(map()) :: {:ok, map()} | {:error, term()}
          def create(data) when is_map(data) do
            Stancer.request(:post, unquote(path), data)
          end
        end

      :get ->
        quote do
          @doc unquote(doc)
          @spec get(String.t()) :: {:ok, map()} | {:error, term()}
          def get(id) when is_binary(id) do
            path = String.replace(unquote(path), "{id}", id)
            Stancer.request(:get, path)
          end
        end

      :update ->
        quote do
          @doc unquote(doc)
          @spec update(String.t(), map()) :: {:ok, map()} | {:error, term()}
          def update(id, data) when is_binary(id) and is_map(data) do
            path = String.replace(unquote(path), "{id}", id)
            Stancer.request(:put, path, data)
          end
        end

      :delete ->
        quote do
          @doc unquote(doc)
          @spec delete(String.t()) :: {:ok, map()} | {:error, term()}
          def delete(id) when is_binary(id) do
            path = String.replace(unquote(path), "{id}", id)
            Stancer.request(:delete, path)
          end
        end

      :other ->
        nil
    end
  end

  defp extract_resource(path) do
    path
    |> String.split("/")
    |> Enum.filter(&(String.length(&1) > 0 && !String.starts_with?(&1, "{")))
    |> List.first()
  end

  defp extract_method_info(path, methods) do
    # Find the first valid HTTP method
    Enum.find_value(methods, fn {method_name, details} ->
      if method_name in ["get", "post", "put", "delete", "patch"] do
        %{
          "method" => String.upcase(method_name),
          "path" => path,
          "description" => Map.get(details, "description", Map.get(details, "summary", ""))
        }
      end
    end)
  end

  defp build_module_doc(resource_name, endpoints) do
    doc = """
    Stancer #{Macro.camelize(resource_name)} API.

    Provides endpoints to manage #{resource_name} in the Stancer payment system.

    ## Functions

    """

    docs =
      endpoints
      |> Enum.map(fn endpoint ->
        action = classify_endpoint(endpoint)
        "- `#{action}/#{action_arity(action)}`"
      end)
      |> Enum.join("\n")

    doc <> docs
  end

  defp build_function_doc(_action, method, path, description) do
    """
    #{method} #{path}

    #{description}

    Returns: `{:ok, response}` on success or `{:error, reason}` on failure
    """
  end

  defp action_arity(:list), do: "0"
  defp action_arity(:create), do: "1"
  defp action_arity(:get), do: "1"
  defp action_arity(:update), do: "2"
  defp action_arity(:delete), do: "1"
end
