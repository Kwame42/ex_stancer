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
  """

  require Logger

  @api_url Application.compile_env(:stancer, :api_url, "https://api.stancer.com")
  @api_version Application.compile_env(:stancer, :api_version, "v1")
  @openapi_url "https://docs.stancer.com/api/openapi.json"

  defp api_key, do: Application.get_env(:stancer, :api_key, "")

  defp request(method, path, body \\ nil, opts \\ []) do
    headers = [
      {"Authorization", "Bearer #{api_key()}"},
      {"Content-Type", "application/json"}
    ]

    url = "#{@api_url}/#{@api_version}#{path}"
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

  @doc """
  Tokenize a card and return a card token.

  Takes a map with card details and returns a card token for future payments.
  """
  def tokenize_card(card_data) when is_map(card_data) do
    request(:post, "/tokens", card_data)
  end

  @doc """
  Create a payment with card authorization (no capture).

  Authorizes the card without capturing the funds.
  """
  def create_payment(payment_data) when is_map(payment_data) do
    request(:post, "/payments", payment_data)
  end

  @doc """
  Get payment details by ID.
  """
  def get_payment(payment_id) when is_binary(payment_id) do
    request(:get, "/payments/#{payment_id}")
  end

  @doc """
  Capture a previously authorized payment.
  """
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
  """
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
  """
  def get_card(card_token) when is_binary(card_token) do
    request(:get, "/cards/#{card_token}")
  end

  @doc """
  Delete a card token.
  """
  def delete_card(card_token) when is_binary(card_token) do
    request(:delete, "/cards/#{card_token}")
  end
end
