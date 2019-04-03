defmodule Utilities do
  @moduledoc """
  Utility functions that don't directly involve success or error.
  """

  @doc """
  A dangerous pattern matching gaurd.
      on_match(expr, pattern, f)
   is equivalent to:
      case expr of
        pattern -> f.(expr)
        _ -> expr

  ## Examples:

      iex> {:bad, 1}
      ...> |> on_match({:good, _}, fn x -> x + 2 end)
      {:bad, 1}

      iex> {:good, 1}
      ...> |> on_match({:good, _}, fn {:good, x} -> x + 2 end)
      3

  """
  # Very handy but shortcuts like this lead people to write very dangerous code
  # where they don't consider all possible cases.
  @doc since: "0.1.1"
  @spec on_match(any, any, (any -> any)) :: any
  defmacro on_match(expr, pattern, f) do
    quote do
      expr = unquote(expr)

      if match?(unquote(pattern), expr) do
        unquote(f).(expr)
      else
        expr
      end
    end
  end

  @doc """
  Given a pattern, it will return a function from expression to boolean.
  This function returns true if the expression matches the pattern and false otherwise.

  ## Examples:

      iex> (match_pred({:good, _})).({:good, 1})
      true

      iex> (match_pred({:good, _})).({:bad, 1})
      false

  """
  @doc since: "0.1.1"
  @spec match_pred(any) :: (any -> boolean)
  defmacro match_pred(pattern) do
    quote do
      fn expr -> match?(unquote(pattern), expr) end
    end
  end

  @doc """
  Partitions an enum of tuples by their first element.
  Returns a map where the keys are the first elements of the tuples
  and the values are enums of the second elements that correspond.
  No guarantee on the order of the returned lists. (In fact they are generally backwards.)

  ## Example:

      iex> [{:ok, 1}, {:error, 2}, {:error, 3}, {:ok, 4}, {:other, 1}]
      ...> |> partition
      %{ok: [4, 1], error: [3, 2], other: [1]}

  """
  @doc since: "0.1.1"
  @spec partition(Enum.t({atom, any})) :: %{required(atom) => Enum.t()}
  def partition(l) do
    Enum.reduce(l, %{}, fn {atom, val}, acc -> Map.update(acc, atom, [val], &[val | &1]) end)
  end
end
