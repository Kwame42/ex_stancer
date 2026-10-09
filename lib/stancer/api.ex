defmodule Stancer.API do
  @moduledoc """
  Stancer API client - all functions are generated dynamically from OpenAPI spec at compile time.

  If Stancer's API changes, the functions are automatically regenerated on recompilation.

  ## Usage

  ```elixir
  # Customers
  Stancer.API.customers_list()
  Stancer.API.customers_create(%{"name" => "John"})
  Stancer.API.customers_get("cust_123")
  Stancer.API.customers_update("cust_123", %{"name" => "Jane"})
  Stancer.API.customers_delete("cust_123")

  # Payments
  Stancer.API.payments_list()
  Stancer.API.payments_create(%{"amount" => 5000, ...})
  Stancer.API.payments_get("paym_123")

  # ... and many more operations
  ```

  All functions return `{:ok, response}` on success or `{:error, reason}` on failure.
  """

  # Load OpenAPI spec at compile time
  @openapi_spec (
    case Stancer.OpenAPILoader.load_spec() do
      {:ok, spec} -> spec
      {:error, _} -> nil
    end
  )

  # Parse and organize resources
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

  # Generate all API functions at compile time
  require Logger
  Logger.info("Stancer.API: Generating #{Enum.count(@operations)} functions from OpenAPI spec")

  for operation <- @operations do
      resource = operation["resource"]
      path = operation["path"]
      method = operation["method"]

      # Classify the operation (list, create, get, update, delete)
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

      # Generate the appropriate function
      case action do
        :list ->
          function_name = :"#{resource}_list"

          def unquote(function_name)() do
            Stancer.request(:get, unquote(path))
          end

        :create ->
          function_name = :"#{resource}_create"

          def unquote(function_name)(data) when is_map(data) do
            Stancer.request(:post, unquote(path), data)
          end

        :get ->
          function_name = :"#{resource}_get"

          def unquote(function_name)(id) when is_binary(id) do
            path = String.replace(unquote(path), ~r/\{[^}]+\}/, id)
            Stancer.request(:get, path)
          end

        :update ->
          function_name = :"#{resource}_update"

          def unquote(function_name)(id, data) when is_binary(id) and is_map(data) do
            path = String.replace(unquote(path), ~r/\{[^}]+\}/, id)
            Stancer.request(:put, path, data)
          end

        :delete ->
          function_name = :"#{resource}_delete"

          def unquote(function_name)(id) when is_binary(id) do
            path = String.replace(unquote(path), ~r/\{[^}]+\}/, id)
            Stancer.request(:delete, path)
          end

        :other ->
          :ok
      end
  end
end
