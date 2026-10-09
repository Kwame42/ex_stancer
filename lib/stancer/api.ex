defmodule Stancer.API do
  @moduledoc """
  Stancer API - resource modules generated dynamically from OpenAPI spec.

  Usage:
  ```
  Stancer.API.Customers.list()
  Stancer.API.Customers.create(%{...})
  Stancer.API.Customers.get(id)
  Stancer.API.Customers.update(id, data)
  Stancer.API.Customers.delete(id)
  ```
  """

  require Logger

  # Load OpenAPI spec
  @openapi_spec (
    case Stancer.OpenAPILoader.load_spec() do
      {:ok, spec} -> spec
      {:error, _} -> nil
    end
  )

  # Parse operations
  @operations (
    if @openapi_spec do
      extract_resource_fn = fn path ->
        path
        |> String.split("/")
        |> Enum.filter(&(String.length(&1) > 0 && !String.starts_with?(&1, "{")))
        |> Enum.filter(&(&1 != "v2"))
        |> List.first()
      end

      extract_method_fn = fn path, methods ->
        Enum.find_value(methods, fn {method_name, details} ->
          if method_name in ["get", "post", "put", "delete", "patch"] do
            %{
              "method" => String.upcase(method_name),
              "path" => path,
              "description" => Map.get(details, "description", "")
            }
          end
        end)
      end

      @openapi_spec
      |> Map.get("paths", %{})
      |> Enum.flat_map(fn {path, methods} ->
        resource = extract_resource_fn.(path)
        if resource do
          method_info = extract_method_fn.(path, methods)
          if method_info do
            [Map.put(method_info, "resource", resource)]
          else
            []
          end
        else
          []
        end
      end)
    else
      []
    end
  )

  # Group by resource
  @resources_map (
    @operations
    |> Enum.group_by(&Map.get(&1, "resource"))
  )

  # Generate modules
  Logger.info("Stancer.API: Generating #{Enum.count(@resources_map)} resource modules")

  for {resource_name, endpoints} <- @resources_map do
    # Classify operations
    operations =
      endpoints
      |> Enum.map(fn op ->
        path = op["path"]
        method = op["method"]

        has_id =
          String.contains?(path, [
            "{id}",
            "{customer_id}",
            "{payment_id}",
            "{card_id}",
            "{payment_intent_id}",
            "{mandate_id}",
            "{dispute_id}",
            "{payout_id}",
            "{webhook_id}",
            "{address_id}",
            "{refund_id}"
          ])

        action =
          case {method, has_id} do
            {"GET", false} -> :list
            {"POST", false} -> :create
            {"GET", true} -> :get
            {"PUT", true} -> :update
            {"PATCH", true} -> :update
            {"DELETE", true} -> :delete
            _ -> :other
          end

        {action, path}
      end)
      |> Enum.filter(fn {action, _} -> action != :other end)
      |> Enum.uniq_by(fn {action, _} -> action end)

    # Generate function definitions
    function_defs =
      Enum.map(operations, fn {action, path} ->
        case action do
          :list ->
            quote do
              @doc "GET #{unquote(path)}\n\nList all #{unquote(resource_name)}."
              @spec list() :: {:ok, map()} | {:error, term()}
              def list do
                Stancer.request(:get, unquote(path))
              end
            end

          :create ->
            quote do
              @doc "POST #{unquote(path)}\n\nCreate a new #{unquote(resource_name)}."
              @spec create(map()) :: {:ok, map()} | {:error, term()}
              def create(data) when is_map(data) do
                Stancer.request(:post, unquote(path), data)
              end
            end

          :get ->
            quote do
              @doc "GET #{unquote(path)}\n\nGet a #{unquote(resource_name)} by ID."
              @spec get(String.t()) :: {:ok, map()} | {:error, term()}
              def get(id) when is_binary(id) do
                path = String.replace(unquote(path), ~r/\{[^}]+\}/, id)
                Stancer.request(:get, path)
              end
            end

          :update ->
            quote do
              @doc "PUT #{unquote(path)}\n\nUpdate a #{unquote(resource_name)}."
              @spec update(String.t(), map()) :: {:ok, map()} | {:error, term()}
              def update(id, data) when is_binary(id) and is_map(data) do
                path = String.replace(unquote(path), ~r/\{[^}]+\}/, id)
                Stancer.request(:put, path, data)
              end
            end

          :delete ->
            quote do
              @doc "DELETE #{unquote(path)}\n\nDelete a #{unquote(resource_name)}."
              @spec delete(String.t()) :: {:ok, map()} | {:error, term()}
              def delete(id) when is_binary(id) do
                path = String.replace(unquote(path), ~r/\{[^}]+\}/, id)
                Stancer.request(:delete, path)
              end
            end
        end
      end)

    # Create the module
    module_name = String.to_atom("Elixir.Stancer.API.#{Macro.camelize(resource_name)}")
    Module.create(module_name, function_defs, Macro.Env.location(__ENV__))
  end
end
