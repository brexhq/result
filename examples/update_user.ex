defmodule Card do
  @moduledoc false
  # Alternatively written :: Result.s(%Card{})
  @spec update_customer_cards(%User{}) ::
              {:ok, %Card{}} | {:error, :not_found} | {:error, reason :: any}
end

defmodule UpdateCustomer do
  @moduledoc """
  Example using Result
  """
  use Result

  def update_customerX(customer_id, params) do
    User
    |> Repo.get(customer_id)
    |> case do
      nil ->
        {:error, :not_found}

      customer ->
        customer
        |> User.changeset(params)
        |> Repo.update()
        |> case do
          {:error, reason} -> {:error, reason}
          {:ok, updated_customer} -> Card.update_customer_cards(updated_customer)
        end
    end
    |> case do
      {:ok, _cards} -> :ok
      {:error, :not_found} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def update_customer(customer_id, params) do
    User
    # customer | nil
    |> Repo.get(customer_id)
    # {ok, customer} | {:error, not_found}
    |> lift(nil, :not_found)
    # {:ok, changeset} | {:error, not_found}
    |> fmap(&User.changeset(&1, params))
    # {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
    ~> Repo.update()
    ~> Card.update_customer_cards()
    # gets rid of result just returns :ok | {:error, reason}
    ~> convert_error(:not_found)
    |> ignore
  end
end
