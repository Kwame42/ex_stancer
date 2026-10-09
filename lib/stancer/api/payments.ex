defmodule Stancer.API.Payments do
  @moduledoc """
  Stancer Payments API.

  Manage payment transactions in the Stancer payment system.

  ## Examples

      # List all payments
      {:ok, payments} = Stancer.API.Payments.list()

      # Create a new payment (authorization)
      {:ok, payment} = Stancer.API.Payments.create(%{
        "amount" => 5000,
        "currency" => "EUR",
        "card" => "card_token",
        "capture" => false
      })

      # Get a specific payment
      {:ok, payment} = Stancer.API.Payments.get("paym_123abc")

      # Update a payment
      {:ok, payment} = Stancer.API.Payments.update("paym_123abc", %{
        "description" => "Updated payment"
      })

      # Delete/cancel a payment
      {:ok, _} = Stancer.API.Payments.delete("paym_123abc")
  """

  @doc """
  GET /payments

  List all payments in your Stancer account.

  Returns: `{:ok, response}` on success or `{:error, reason}` on failure
  """
  @spec list() :: {:ok, map()} | {:error, term()}
  def list do
    Stancer.request(:get, "/payments")
  end

  @doc """
  POST /payments

  Create a new payment transaction.

  Parameters:
  - `data`: Map containing payment information
    - `amount` (required): Amount in cents (e.g., 5000 = €50.00)
    - `currency` (required): Currency code (e.g., "EUR", "USD")
    - `card` (required): Card token or card ID
    - `capture` (optional): Whether to capture immediately (default: true)

  Returns: `{:ok, payment}` on success or `{:error, reason}` on failure
  """
  @spec create(map()) :: {:ok, map()} | {:error, term()}
  def create(data) when is_map(data) do
    Stancer.request(:post, "/payments", data)
  end

  @doc """
  GET /payments/{id}

  Retrieve a specific payment by ID.

  Parameters:
  - `id`: Payment ID (e.g., "paym_123abc")

  Returns: `{:ok, payment}` on success or `{:error, reason}` on failure
  """
  @spec get(String.t()) :: {:ok, map()} | {:error, term()}
  def get(id) when is_binary(id) do
    Stancer.request(:get, "/payments/#{id}")
  end

  @doc """
  PUT /payments/{id}

  Update a payment.

  Parameters:
  - `id`: Payment ID (e.g., "paym_123abc")
  - `data`: Map containing fields to update

  Returns: `{:ok, payment}` on success or `{:error, reason}` on failure
  """
  @spec update(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def update(id, data) when is_binary(id) and is_map(data) do
    Stancer.request(:put, "/payments/#{id}", data)
  end

  @doc """
  DELETE /payments/{id}

  Cancel or delete a payment.

  Parameters:
  - `id`: Payment ID (e.g., "paym_123abc")

  Returns: `{:ok, %{}}` on success or `{:error, reason}` on failure
  """
  @spec delete(String.t()) :: {:ok, map()} | {:error, term()}
  def delete(id) when is_binary(id) do
    Stancer.request(:delete, "/payments/#{id}")
  end
end
