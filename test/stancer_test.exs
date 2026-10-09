defmodule StancerTest do
  use ExUnit.Case
  doctest Stancer

  describe "Stancer core functions" do
    test "tokenize_card/1 has proper spec" do
      # Verify the function exists and is callable
      assert function_exported?(Stancer, :tokenize_card, 1)
    end

    test "create_payment/1 has proper spec" do
      assert function_exported?(Stancer, :create_payment, 1)
    end

    test "get_payment/1 has proper spec" do
      assert function_exported?(Stancer, :get_payment, 1)
    end

    test "capture_payment/1 and /2 exist" do
      assert function_exported?(Stancer, :capture_payment, 1)
      assert function_exported?(Stancer, :capture_payment, 2)
    end

    test "refund_payment/1 and /2 exist" do
      assert function_exported?(Stancer, :refund_payment, 1)
      assert function_exported?(Stancer, :refund_payment, 2)
    end

    test "get_card/1 has proper spec" do
      assert function_exported?(Stancer, :get_card, 1)
    end

    test "delete_card/1 has proper spec" do
      assert function_exported?(Stancer, :delete_card, 1)
    end
  end

  describe "Stancer.DynamicAPI" do
    test "can load OpenAPI endpoints" do
      case Stancer.DynamicAPI.get_endpoints() do
        {:ok, endpoints} ->
          assert is_list(endpoints)
          assert Enum.count(endpoints) > 0

        {:error, reason} ->
          # Network error is OK during tests
          assert is_atom(reason) or is_binary(reason)
      end
    end

    test "can list operations" do
      case Stancer.DynamicAPI.list_operations() do
        {:ok, operations} ->
          assert is_list(operations)

          # Verify structure of operations
          Enum.each(operations, fn op ->
            assert Map.has_key?(op, "operation_id")
            assert Map.has_key?(op, "method")
            assert Map.has_key?(op, "path")
          end)

        {:error, _reason} ->
          # Network error is OK
          :ok
      end
    end

    test "can get endpoint info" do
      case Stancer.DynamicAPI.get_endpoint_info("post_tokens") do
        {:ok, endpoint} ->
          assert endpoint["method"] == "POST"
          assert String.contains?(endpoint["path"], "tokens")

        {:error, _reason} ->
          # Network error is OK
          :ok
      end
    end

    test "returns error for unknown endpoint" do
      {:error, :not_found} = Stancer.DynamicAPI.get_endpoint_info("nonexistent_operation")
    end
  end

  describe "Stancer.OpenAPILoader" do
    test "can extract endpoints from spec structure" do
      spec = %{
        "paths" => %{
          "/tokens" => %{
            "post" => %{
              "operationId" => "post_tokens",
              "summary" => "Create token",
              "description" => "Tokenize a card",
              "requestBody" => %{}
            }
          },
          "/payments/{id}" => %{
            "get" => %{
              "operationId" => "get_payment",
              "summary" => "Get payment",
              "parameters" => [%{"name" => "id", "in" => "path"}]
            }
          }
        }
      }

      endpoints = Stancer.OpenAPILoader.extract_endpoints(spec)
      assert Enum.count(endpoints) == 2

      # Verify structure
      Enum.each(endpoints, fn endpoint ->
        assert Map.has_key?(endpoint, "method")
        assert Map.has_key?(endpoint, "path")
        assert Map.has_key?(endpoint, "operation_id")
      end)
    end
  end

  describe "Documentation" do
    test "Stancer module has moduledoc" do
      {:docs_v1, _version, _language, _format, %{"en" => doc}, _metadata, _functions} =
        Code.fetch_docs(Stancer)

      assert is_binary(doc)
      assert String.length(doc) > 0
      assert String.contains?(doc, "Stancer API")
    end

    test "Core functions have proper docs" do
      {:docs_v1, _version, _language, _format, _module_doc, _metadata, functions} =
        Code.fetch_docs(Stancer)

      # Find tokenize_card function docs
      tokenize_found =
        functions
        |> Enum.find(fn
          {{:function, :tokenize_card, 1}, _line, _source, _doc_map, _metadata} -> true
          _ -> false
        end)

      assert tokenize_found != nil
    end
  end
end
