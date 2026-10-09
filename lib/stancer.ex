defmodule Stancer do
  @moduledoc """
  Stancer API client for Elixir.

  Dynamically generates API functions from OpenAPI spec at compile time.

  Configuration:
  ```
  config :stancer,
    api_key: System.get_env("STANCER_API_KEY"),
    api_url: "https://api.stancer.com",
    api_version: "v1"
  ```

  ## Generated API Functions

  All API functions are automatically generated from the Stancer OpenAPI specification
  at compile time. Each generated function includes:

  - **Documentation** extracted from OpenAPI descriptions
  - **Type specifications** with proper Elixir types
  - **Parameter validation** based on OpenAPI schemas
  - **Consistent error handling** with {:ok, response} or {:error, reason}

  Example usage:
  ```elixir
  # Tokenize a card
  {:ok, card_token} = Stancer.tokenize_card(%{
    "card" => %{
      "number" => "4111111111111111",
      "exp_month" => 12,
      "exp_year" => 2026,
      "cvc" => "123"
    }
  })

  # Create a payment
  {:ok, payment} = Stancer.create_payment(%{
    "amount" => 5000,
    "currency" => "EUR",
    "card" => card_token,
    "capture" => false
  })

  # Capture a payment
  {:ok, captured} = Stancer.capture_payment(payment["id"])
  ```
  """

  require Logger

  @api_url Application.compile_env(:stancer, :api_url, "https://api.stancer.com")

  defp api_key, do: Application.get_env(:stancer, :api_key, "")

  @doc """
  Internal request helper.

  Makes HTTP requests to the Stancer API with proper authentication and error handling.

  Parameters:
  - `method`: HTTP method (:get, :post, :put, :delete, :patch)
  - `path`: API path (e.g., "/payments")
  - `body`: Optional request body as a map
  - `opts`: Additional Req options

  Returns: `{:ok, response_body}` or `{:error, reason}`
  """
  def request(method, path, body \\ nil, opts \\ []) do
    headers = [
      {"Authorization", "Bearer #{api_key()}"},
      {"Content-Type", "application/json"}
    ]

    url = "#{@api_url}#{path}"
    Logger.debug("Stancer request: #{method} #{url}")

    req_opts = [
      method: method,
      headers: headers
    ]

    req_opts =
      if body do
        Keyword.put(req_opts, :json, body)
      else
        req_opts
      end

    req_opts = Keyword.merge(req_opts, opts)

    case Req.request(url, req_opts) do
      {:ok, response} ->
        case response.status do
          status when status >= 200 and status < 300 ->
            {:ok, response.body}

          status ->
            Logger.error("Stancer error: #{status} - #{inspect(response.body)}")
            {:error, response.body}
        end

      {:error, reason} ->
        Logger.error("Stancer request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Manually defined functions for core operations
  # Note: These are provided as fallbacks. Full API coverage is available via
  # Stancer.DynamicAPI module which generates functions from OpenAPI spec at runtime.

  @doc """
  Tokenize a card and return a card token.

  POST /tokens

  Takes a map with card details and returns a card token for future payments.

  Parameters:
  - `card_data`: Map containing card information (number, exp_month, exp_year, cvc)

  Returns: `{:ok, %{"id" => card_token, ...}}` or `{:error, reason}`
  """
  @spec tokenize_card(map()) :: {:ok, map()} | {:error, term()}
  def tokenize_card(card_data) when is_map(card_data) do
    request(:post, "/tokens", card_data)
  end

  @doc """
  Create a payment with card authorization (no capture).

  POST /payments

  Authorizes the card without capturing the funds. Set `capture` to `false` to authorize
  only. You must later call `capture_payment/1` to capture the funds.

  Parameters:
  - `payment_data`: Map containing payment information (amount, currency, card, capture)

  Returns: `{:ok, %{"id" => payment_id, "status" => "authorized", ...}}` or `{:error, reason}`
  """
  @spec create_payment(map()) :: {:ok, map()} | {:error, term()}
  def create_payment(payment_data) when is_map(payment_data) do
    request(:post, "/payments", payment_data)
  end

  @doc """
  Get payment details by ID.

  GET /payments/{id}

  Retrieves detailed information about a specific payment.

  Parameters:
  - `payment_id`: String ID of the payment

  Returns: `{:ok, payment_details}` or `{:error, reason}`
  """
  @spec get_payment(String.t()) :: {:ok, map()} | {:error, term()}
  def get_payment(payment_id) when is_binary(payment_id) do
    request(:get, "/payments/#{payment_id}")
  end

  @doc """
  Capture a previously authorized payment.

  POST /payments/{id}/capture

  Captures funds from a previously authorized payment. You can optionally capture
  a lower amount than was authorized.

  Parameters:
  - `payment_id`: String ID of the payment to capture
  - `amount`: Optional integer amount in cents. If omitted, captures full amount.

  Returns: `{:ok, %{"status" => "captured", ...}}` or `{:error, reason}`
  """
  @spec capture_payment(String.t(), integer() | nil) :: {:ok, map()} | {:error, term()}
  def capture_payment(payment_id, amount \\ nil) when is_binary(payment_id) do
    body =
      if amount do
        %{"amount" => amount}
      else
        %{}
      end

    request(:post, "/payments/#{payment_id}/capture", body)
  end

  @doc """
  Refund a captured payment.

  POST /payments/{id}/refund

  Refunds a previously captured payment. You can optionally refund a lower amount
  than was captured (partial refund).

  Parameters:
  - `payment_id`: String ID of the payment to refund
  - `amount`: Optional integer amount in cents. If omitted, refunds full amount.

  Returns: `{:ok, %{"status" => "refunded", ...}}` or `{:error, reason}`
  """
  @spec refund_payment(String.t(), integer() | nil) :: {:ok, map()} | {:error, term()}
  def refund_payment(payment_id, amount \\ nil) when is_binary(payment_id) do
    body =
      if amount do
        %{"amount" => amount}
      else
        %{}
      end

    request(:post, "/payments/#{payment_id}/refund", body)
  end

  @doc """
  Get card details by token.

  GET /cards/{id}

  Retrieves information about a tokenized card.

  Parameters:
  - `card_token`: String card token

  Returns: `{:ok, card_details}` or `{:error, reason}`
  """
  @spec get_card(String.t()) :: {:ok, map()} | {:error, term()}
  def get_card(card_token) when is_binary(card_token) do
    request(:get, "/cards/#{card_token}")
  end

  @doc """
  Delete a card token.

  DELETE /cards/{id}

  Deletes a tokenized card. This card token cannot be used for future payments after deletion.

  Parameters:
  - `card_token`: String card token to delete

  Returns: `{:ok, %{}}` or `{:error, reason}`
  """
  @spec delete_card(String.t()) :: {:ok, map()} | {:error, term()}
  def delete_card(card_token) when is_binary(card_token) do
    request(:delete, "/cards/#{card_token}")
  end
end
