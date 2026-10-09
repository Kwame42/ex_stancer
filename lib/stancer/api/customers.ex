defmodule Stancer.API.Customers do
  @moduledoc """
  Stancer Customers API.

  Manage customer profiles in the Stancer payment system.

  ## Examples

      # List all customers
      {:ok, customers} = Stancer.API.Customers.list()

      # Create a new customer
      {:ok, customer} = Stancer.API.Customers.create(%{
        "name" => "John Doe",
        "email" => "john@example.com"
      })

      # Get a specific customer
      {:ok, customer} = Stancer.API.Customers.get("cust_123abc")

      # Update a customer
      {:ok, customer} = Stancer.API.Customers.update("cust_123abc", %{
        "name" => "Jane Doe"
      })

      # Delete a customer
      {:ok, _} = Stancer.API.Customers.delete("cust_123abc")
  """

  @doc """
  GET /customers

  List all customers in your Stancer account.

  Returns: `{:ok, response}` on success or `{:error, reason}` on failure
  """
  @spec list() :: {:ok, map()} | {:error, term()}
  def list do
    Stancer.request(:get, "/customers")
  end

  @doc """
  POST /customers

  Create a new customer profile.

  Parameters:
  - `data`: Map containing customer information (name, email, etc.)

  Returns: `{:ok, customer}` on success or `{:error, reason}` on failure
  """
  @spec create(map()) :: {:ok, map()} | {:error, term()}
  def create(data) when is_map(data) do
    Stancer.request(:post, "/customers", data)
  end

  @doc """
  GET /customers/{id}

  Retrieve a specific customer by ID.

  Parameters:
  - `id`: Customer ID (e.g., "cust_123abc")

  Returns: `{:ok, customer}` on success or `{:error, reason}` on failure
  """
  @spec get(String.t()) :: {:ok, map()} | {:error, term()}
  def get(id) when is_binary(id) do
    Stancer.request(:get, "/customers/#{id}")
  end

  @doc """
  PUT /customers/{id}

  Update a customer profile.

  Parameters:
  - `id`: Customer ID (e.g., "cust_123abc")
  - `data`: Map containing fields to update (name, email, etc.)

  Returns: `{:ok, customer}` on success or `{:error, reason}` on failure
  """
  @spec update(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def update(id, data) when is_binary(id) and is_map(data) do
    Stancer.request(:put, "/customers/#{id}", data)
  end

  @doc """
  DELETE /customers/{id}

  Delete a customer profile.

  Parameters:
  - `id`: Customer ID (e.g., "cust_123abc")

  Returns: `{:ok, %{}}` on success or `{:error, reason}` on failure
  """
  @spec delete(String.t()) :: {:ok, map()} | {:error, term()}
  def delete(id) when is_binary(id) do
    Stancer.request(:delete, "/customers/#{id}")
  end
end
