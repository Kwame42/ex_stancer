defmodule Stancer.API.Cards do
  @moduledoc """
  Stancer Cards API.

  Manage tokenized card data in the Stancer payment system.

  ## Examples

      # Create a new card token
      {:ok, card} = Stancer.API.Cards.create(%{
        "number" => "4111111111111111",
        "exp_month" => 12,
        "exp_year" => 2026,
        "cvc" => "123"
      })

      # Get a specific card
      {:ok, card} = Stancer.API.Cards.get("card_123abc")

      # Update a card
      {:ok, card} = Stancer.API.Cards.update("card_123abc", %{
        "exp_month" => 6,
        "exp_year" => 2027
      })

      # Delete a card
      {:ok, _} = Stancer.API.Cards.delete("card_123abc")
  """

  @doc """
  POST /tokens (or POST /cards)

  Create a new card token.

  Parameters:
  - `data`: Map containing card information
    - `number` (required): 16-digit card number
    - `exp_month` (required): Expiration month (1-12)
    - `exp_year` (required): Expiration year (4-digit)
    - `cvc` (required): Card verification code

  Returns: `{:ok, card}` with token on success or `{:error, reason}` on failure
  """
  @spec create(map()) :: {:ok, map()} | {:error, term()}
  def create(data) when is_map(data) do
    Stancer.request(:post, "/tokens", data)
  end

  @doc """
  GET /cards/{id}

  Retrieve a specific card token by ID.

  Parameters:
  - `id`: Card token/ID (e.g., "card_123abc")

  Returns: `{:ok, card}` on success or `{:error, reason}` on failure
  """
  @spec get(String.t()) :: {:ok, map()} | {:error, term()}
  def get(id) when is_binary(id) do
    Stancer.request(:get, "/cards/#{id}")
  end

  @doc """
  PUT /cards/{id}

  Update a card token.

  Parameters:
  - `id`: Card token/ID (e.g., "card_123abc")
  - `data`: Map containing fields to update (exp_month, exp_year, etc.)

  Returns: `{:ok, card}` on success or `{:error, reason}` on failure
  """
  @spec update(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def update(id, data) when is_binary(id) and is_map(data) do
    Stancer.request(:put, "/cards/#{id}", data)
  end

  @doc """
  DELETE /cards/{id}

  Delete a card token. This card can no longer be used for payments.

  Parameters:
  - `id`: Card token/ID (e.g., "card_123abc")

  Returns: `{:ok, %{}}` on success or `{:error, reason}` on failure
  """
  @spec delete(String.t()) :: {:ok, map()} | {:error, term()}
  def delete(id) when is_binary(id) do
    Stancer.request(:delete, "/cards/#{id}")
  end
end
