defmodule ExResult.Mappers do
  @moduledoc """
  Tools for combining `Enum` and `ok`/`error` tuples.
  """
  import ExResult.Base
  alias ExResult.Base

  @typep a :: any()
  @typep b :: any()

  @type s(x) :: Base.s(x)
  @type t(x) :: Base.t(x)

  @type p() :: Base.p()
  @type s() :: Base.s()
  @type t() :: Base.t()

  @doc """
  Binds the function to each tuple in the enum.

  ## Example:

      iex> [{:ok, 1}, {:ok, 2}, {:error, 3}, {:ok, 4}]
      ...> |> map_with_bind(fn x -> if x == 2, do: {:error, x*6}, else: {:ok, x*6} end)
      [{:ok, 6}, {:error, 12}, {:error, 3}, {:ok, 24}]

  """
  @doc since: "0.1.0"
  @spec map_with_bind(Enum.t(s(a)), (a -> s(b))) :: Enum.t(s(b))
  def map_with_bind(l, f), do: Enum.map(l, &bind(&1, f))

  @doc """
  Given an enumerable of plain values,
  it returns `{:ok, processed enum}` or the first `error`.
  Equivalent to traverse or mapM in Haskell.

  ## Examples:

      iex> [1, 2, 3, 4]
      ...> |> map_while_success(fn x -> if x == 3 || x == 1, do: {:error, x}, else: {:ok, x} end)
      {:error, 1}

      iex> map_while_success([1, 2, 3, 4], fn x -> {:ok, x + 2} end)
      {:ok, [3, 4, 5, 6]}

  """
  @doc since: "0.1.0"
  @spec map_while_success(Enum.t(a), (a -> t(b))) :: s(Enum.t(b))
  def map_while_success(l, f) do
    l
    |> Enum.reduce_while({:ok, []}, fn x, acc ->
      case f.(x) do
        :ok -> {:cont, acc}
        {:ok, val} -> {:cont, fmap(acc, &[val | &1])}
        {:error, r} -> {:halt, {:error, r}}
      end
    end)
    |> fmap(&Enum.reverse/1)
  end

  @doc """
  Given an enum of plain values, an initial value, and a reducing function,
  it returns the first `error` or reduced result.

  ## Examples:
      iex> [1, 2, 3, 4]
      ...> |> reduce_while_success({:ok, 100}, &{:ok, &1  + &2})
      {:ok, 110}

      iex> [1, 2, 3, 4]
      ...> |> reduce_while_success({:ok, 100}, fn x, acc ->
      ...>   if x > 2 do
      ...>     {:error, x}
      ...>   else
      ...>     {:ok, x + acc}
      ...>   end
      ...> end)
      {:error, 3}

  """
  @doc since: "0.1.2"
  @spec reduce_while_success(Enum.t(a), t(b), (a, b -> t(b))) :: t(b)
  def reduce_while_success(ms, b, f) do
    Enum.reduce_while(ms, b, fn a, acc ->
      case bind(acc, &f.(a, &1)) do
        {:ok, val} -> {:cont, {:ok, val}}
        {:error, r} -> {:halt, {:error, r}}
      end
    end)
  end

  @doc """
  Applies the function to each element of the enumerable until an error occurs.
  No guarentee on the order of evaluation. (But usually backwards for lists.)
  Only takes a function that returns `:ok | {:error, value}`.

  ## Examples:

      iex> [1, 2, 3, 4]
      ...> |> each_while_success(fn x -> if x < 3, do: :ok, else: {:error, :too_big} end)
      {:error, :too_big}

      iex> [1, 2, 3, 4]
      ...> |> each_while_success(fn x -> if x < 5, do: :ok, else: {:error, :too_big} end)
      :ok

  """
  @doc since: "0.1.1"
  @spec each_while_success(Enum.t(a), (a -> p())) :: p()
  def each_while_success(ms, f) do
    Enum.reduce_while(ms, :ok, fn x, _acc ->
      case f.(x) do
        :ok -> {:cont, :ok}
        {:error, r} -> {:halt, {:error, r}}
      end
    end)
  end
end
