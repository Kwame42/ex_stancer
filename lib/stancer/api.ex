defmodule Stancer.API do
  @moduledoc """
  Stancer API client organized by resource.

  Provides a clean, hierarchical API structure for the Stancer payment processor.

  ## Usage Examples

  ### Customers
  ```elixir
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
  ```

  ### Payments
  ```elixir
  # Create a payment
  {:ok, payment} = Stancer.API.Payments.create(%{
    "amount" => 5000,
    "currency" => "EUR",
    "card" => card_token,
    "capture" => false
  })

  # Get payment details
  {:ok, payment} = Stancer.API.Payments.get("paym_123abc")
  ```

  ### Cards
  ```elixir
  # Tokenize a card
  {:ok, card} = Stancer.API.Cards.create(%{
    "number" => "4111111111111111",
    "exp_month" => 12,
    "exp_year" => 2026,
    "cvc" => "123"
  })

  # Get card details
  {:ok, card} = Stancer.API.Cards.get("card_123abc")
  ```

  ## Available Resources

  - `Stancer.API.Customers` - Manage customer profiles
  - `Stancer.API.Payments` - Manage payment transactions
  - `Stancer.API.Cards` - Manage tokenized cards

  More resources coming soon based on the Stancer OpenAPI specification.

  ## Standard Resource Functions

  Each resource module provides these standard CRUD operations:

  - `list/0` - List all resources
  - `create/1` - Create a new resource
  - `get/1` - Get a specific resource by ID
  - `update/2` - Update a resource
  - `delete/1` - Delete a resource

  All functions return `{:ok, response}` on success or `{:error, reason}` on failure.

  ## Design Philosophy

  The Stancer.API modules follow RESTful principles and provide:

  - **Clear naming** - Function names match HTTP operations (get, create, update, delete)
  - **Consistent signatures** - All resource modules have the same interface
  - **Type safety** - Functions include `@spec` declarations for Dialyzer
  - **Documentation** - Each function is fully documented with examples
  - **Error handling** - All functions return standard `{:ok, _} | {:error, _}` tuples
  """
end
