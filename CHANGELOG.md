# Changelog

## v0.1.3 04/10/19

**Removed**

```elixir
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
    @spec on_match(any, any, (any -> any)) :: any
```

```elixir
    @doc """
    Given a pattern, it will return a function from expression to boolean.
    This function returns true if the expression matches the pattern and false otherwise.

    ## Examples:

        iex> (match_pred({:good, _})).({:good, 1})
        true

        iex> (match_pred({:good, _})).({:bad, 1})
        false

    """
    @spec match_pred(any) :: (any -> boolean)
```

```elixir
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
    @spec partition(Enum.t({atom, any})) :: %{required(atom) => Enum.t()}
```

**Removed**

```elixir
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
    @spec on_match(any, any, (any -> any)) :: any
```

```elixir
    @doc """
    Given a pattern, it will return a function from expression to boolean.
    This function returns true if the expression matches the pattern and false otherwise.

    ## Examples:

        iex> (match_pred({:good, _})).({:good, 1})
        true

        iex> (match_pred({:good, _})).({:bad, 1})
        false

    """
    @spec match_pred(any) :: (any -> boolean)
```

```elixir
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
    @spec partition(Enum.t({atom, any})) :: %{required(atom) => Enum.t()}
```

**Changed:**

- s/`~>>`/`~>`/g and eliminated nested capture problem
- split `Base`, `Helpers`, and `Mappers` into different files
- created a `using` macro to `import` entire library

## v0.1.2 03/25/19

**Added:**

```elixir
    @doc """
    Wraps a naked `:error` atom in a tuple with the given reason.
    Leaves success values and `error` tuples unchanged.
    ## Examples:
        iex> :error
        ...> |> normalize_error(:parsing_failure)
        {:error, :parsing_failure}

        iex> {:ok, 2}
        ...> |> normalize_error()
        {:ok, 2}
    """
    @spec normalize_error(any, any) :: t()
```

**Removed:**

```elixir
    @doc """
    Returns :ok
    Will be inlined at compile time.
    """
    @spec ok() :: :ok


    @doc """
    If the first argument is success then it returns the second, else it propogates the first error.
    Lazy. Only evaluates the second argument if necessary.

    ## Examples:
          iex> sequencing({:ok, 1}, {:ok, 2})
          {:ok, 2}
          iex> sequencing({:error, 3}, {:error, 4})
          {:error, 3}
          iex> sequencing({:ok, 1}, :ok)
          :ok
    """
    @spec sequencing(t(a), t(b)) :: t(b)
```

```elixir
    @doc """
      Infix sequencing.
      Lazy. Only evaluates the second argument if necessary.

        ## Examples:
            iex> {:ok, 1}
            ...> ~> {:ok, 2}
            ...> ~> {:error, 3}
            ...> ~> {:error, 4}
            {:error, 3}
            iex> {:ok, 1}
            ...> ~> {:ok, 2}
            ...> ~> {:ok, 3}
            {:ok, 3}
    """
    @spec t(a) ~> t(b) :: t(b)
```

```elixir
    @doc "Returns true if the given argument is an error tuple."
    @spec is_error(t(a)) :: boolean
```

```elixir
    @doc "Returns true if the given argument is :ok, or an ok tuple."
    @spec is_ok(t(a)) :: boolean
```

```elixir
    @doc "Flips an ok tuple to an error tuple and an error tuple to an ok tuple."
    @spec flip(s(a)) :: s(b)
```

```elixir
    @doc """
    Given an enum of plain values, an initial value, and a reducing function,
    it returns the first `error` or reduced result.
    ## Examples:
      iex> [{:ok, 1}, {:error, 2}, {:error, 3}, {:ok, 4}]
      ...> |> sequence
      {:error, 2}
      iex> [{:ok, 1}, {:ok, 2}, {:ok, 3}, {:ok, 4}]
      ...> |> sequence
      {:ok, [1, 2, 3, 4]}
    """
    @spec sequence(Enum.t(s(a))) :: s(Enum.t(a))
```

```elixir
    @doc """
    Given an enum of tuples, an initial value, and a reducing function, it returns the first error
    or reduced result.
    ## Examples:
      iex> [{:ok, 1}, {:ok, 2}, {:ok, 3}, {:ok, 4}]
      ...> |> reduce_unless_error({:ok, 100}, &{:ok, &1  + &2})
      {:ok, 110}
    @spec reduce_unless_error(Enum.t(s(a)), s(a), ((a, b) -> s(b))) ::  s(b)
```

```elixir
    @doc """
    Given an enum of tuples and a reducing function, it returns the first error
    or reduced result.
    Does not require an initial result, instead it uses the first element of the enum.
    Raises an error on empty list and simply returns the value on singletons.
    ## Examples:
      iex> [{:ok, 1}, {:ok, 2}, {:ok, 3}, {:ok, 4}]
      ...> |> reduce_unless_error(&{:ok, &1  + &2})
      {:ok, 10}
      iex> [{:ok, 1}, {:error, 2}, {:ok, 3}, {:error, 4}]
      ...> |> reduce_unless_error(&{:ok, &1 + &2})
      {:error, 2}
    """
    @spec reduce_unless_error(Enum.t(s(a)), ((a, b) -> s(b))) ::  s(b) | s(a)
```

```elixir
    @doc """
    Returns first error or returns last element in enum.
    ## Examples:
        iex> [{:ok, 1}, {:error, 3}, {:ok, 2}, {:error, 4}]
        ...> |> stop_at_first_error
        {:error, 3}
        iex> [{:ok, 1}, {:ok, 2}, {:ok, 3}, {:ok, 4}]
        ...> |> stop_at_first_error
        {:ok, 4}
    """
    @spec stop_at_first_error(Enum.t(t(a))) :: t(a)
```

```elixir
    @doc """
    Returns an enum of values that were successful and passed the filtering function.
    ## Examples:
      iex> [{:ok, 1}, {:error, 2}, {:error, 3}, {:ok, 4}]
      ...> |> filter(fn x -> x < 3 end)
      {:ok, [1]}
      iex> [{:ok, 1}, {:error, 2}, {:error, 3}, {:ok, 4}]
      ...> |> filter(fn _ -> true end)
      {:ok, [1, 4]}
    """
    @spec filter(Enum.t(s(a)), (a -> boolean)) :: t(Enum.t(a))
```

**Other Changes:**

s/`extract`/`extract!`/g

```elixir
    @doc """
    Extracts the value or reason from the tuple.
    Caution: If given an `error` tuple it raise an exception!
    """
    @spec extract!(s(a)) :: a
```

```elixir
    @doc "Extracts the value or reason from the tuple."
    @spec extract(s(a)) :: a
```

Enforced return type on `bind/2`

## v0.1.1 12/11/18

**Added:**

```elixir
    @doc """
    Ignores the value in an ok tuple and just returns :ok.
    Still shortcircuits on error.
    ## Examples:
        iex> {:ok, 2}
        ...> |> ignore
        :ok
        iex> :ok
        ...> |> ignore
        :ok
        iex> {:error, :not_found}
        ...> |> ignore
        {:error, :not_found}
    """
    @spec ignore(t(a)) :: p()
    def ignore(ma), do: sequencing(ma, :ok)
```

```elixir
    @doc """
    Applies the function to each element of the enumerable until an error occurs.
    No guarentee on the order of evaluation. (But usually backwards for lists.)
    Only takes a function that returns :ok | {:error, value}.
    ## Examples:
        iex> [1, 2, 3, 4]
        ...> |> each_while_success(fn x -> if x < 3, do: :ok, else: {:error, :too_big} end)
        {:error, :too_big}
        iex> [1, 2, 3, 4]
        ...> |> each_while_success(fn x -> if x < 5, do: :ok, else: {:error, :too_big} end)
        :ok
    """
    @spec each_while_success(Enum.t(a), (a -> p())) :: p()
```

**Other Changes:**

Added laziness to:

```elixir
    @doc """
    If the first argument is success then it returns the second, else it propogates the first error.
    Lazy. Only evaluates the second argument if necessary.
    ## Examples:
        iex> sequencing({:ok, 1}, {:ok, 2})
        {:ok, 2}
        iex> sequencing({:error, 3}, {:error, 4})
        {:error, 3}
        iex> sequencing({:ok, 1}, :ok)
        :ok
        iex> sequencing(:ok, {:ok, 1})
        {:ok, 1}
    """
    @spec sequencing(t(a), t(b)) :: t(b)
```

```elixir
    @doc """
    Infix sequencing.
    Lazy. Only evaluates the second argument if necessary.
    ## Examples:
        iex> {:ok, 1}
        ...> ~> {:ok, 2}
        ...> ~> {:error, 3}
        ...> ~> {:error, 4}
        {:error, 3}
        iex> {:ok, 1}
        ...> ~> {:ok, 2}
        ...> ~> {:ok, 3}
        {:ok, 3}
        iex> {:ok, 1}
        ...> ~> :ok
        :ok
    """
    @spec t(a) ~> t(b) :: t(b)
```

```elixir
    @doc """
    Replaces the reason in an error tuple.
    Leaves success unchanged.
    Lazy. Only evaluates the second argument if necessary.
    ## Example:
        iex> account_name = "test"
        ...> {:error, :not_found}
        ...> |> mask_error({:nonexistent_account, account_name})
        {:error, {:nonexistent_account, "test"}}
    """
    @spec mask_error(t(a), any) :: t(a)
```

```elixir
    @doc """
    Converts a matching error to a success with the given value or function.
    An error matches if the reason is equal to the supplied atom or the reason passes the predicate.
    Leaves success and other errors unchanged.
    Lazy. Only evaluates the second argument if necessary.
    ## Example:
        iex> {:error, :already_completed}
        ...> |> convert_error(:already_completed, "submitted")
        {:ok, "submitted"}
        iex> {:error, "test"}
        ...> |> convert_error(&(&1 == "test"), fn r -> {:ok, r <> "ed"} end)
        {:ok, "tested"}
    """
    @spec convert_error(t(a), (any -> boolean) | any, b | (any -> t(b))) :: t(b)
```

```elixir
    @doc """
    Lifts a value into a success tuple unless:
    1) the value matches the second argument
    2) when applied to the value, the second argument function returns true
    In those cases an error tuple is returned with either
    1) the third argument as the reason
    2) the third argument function applied to the value, as the reason
    lift is lazy, this means third argument will only be evaluated when necessary.
    ## Examples:
        iex> nil
        ...> |> lift(nil, :not_found)
        {:error, :not_found}
        iex> 2
        ...> |> lift(nil, :not_found)
        {:ok, 2}
        iex> "test"
        ...> |> lift(&(&1 == "test"), fn x -> {:oops, x <> "ed"} end)
        {:error, {:oops, "tested"}}
    """
    @spec lift(a | b, b | (a | b -> boolean), c | (a | b -> c)) :: s(a)
```

## v0.1.0 11/30/18

Initial version!
