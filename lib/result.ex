defmodule Result do
  @moduledoc """
  A library to handle error and success results and propagation.
      :ok | {:ok, val} | {:error, reason}
  Similar to the Either Monad in Haskell
  """
  @moduledoc since: "0.1.0"

  require Logger

  @typep a :: any()
  @typep b :: any()
  @typep c :: any()

  @type s(x) :: {:ok, x} | {:error, any}
  @type t(x) :: :ok | s(x)

  @type p() :: :ok | {:error, any}
  @type s() :: s(any)
  @type t() :: t(any)

  @doc """
  Returns :ok
  Will be inlined at compile time.
  """
  @doc since: "0.1.0"
  @doc result: :base
  @spec ok() :: t(a)
  defmacro ok(), do: :ok

  @doc """
  Wraps value in an ok tuple.
  Will be inlined at compile time.
  """
  @doc since: "0.1.0"
  @doc result: :base
  @spec ok(a) :: s(a)
  defmacro ok(val), do: {:ok, val}

  @doc """
  Wraps value in an error tuple.
  Will be inlined at compile time.
  """
  @doc since: "0.1.0"
  @doc result: :base
  @spec error(any) :: t(a)
  defmacro error(r), do: {:error, r}

  @doc """
  Applies the function to the value within the ok tuple or propogates the error.
  ## Examples:
      iex> bind({:ok, 1}, fn x -> if x == 1, do: {:ok, 2}, else: {:error, "not_one"} end)
      {:ok, 2}
      iex> bind({:ok, 4}, fn x -> if x == 1, do: {:ok, 2}, else: {:error, "not_one"} end)
      {:error, "not_one"}
      iex> bind({:error, 4}, fn x -> if x == 1, do: {:ok, 2}, else: {:error, "not_one"} end)
      {:error, 4}
  """
  @doc since: "0.1.0"
  @doc result: :base
  @spec bind(s(a), (a -> s(b))) :: s(b)
  def bind({:ok, v}, f), do: f.(v)
  def bind({:error, r}, _), do: {:error, r}

  # bind/3 has the same behavior as bind but takes
  # two tuples and a function that combines their values.
  @doc since: "0.1.0"
  @doc result: :base
  @spec bind(s(a), s(b), (a, b -> s(c))) :: s(c)
  defp bind(ma, mb, f) do
    case {ma, mb} do
      {{:ok, v1}, {:ok, v2}} -> f.(v1, v2)
      {{:error, r}, {:ok, _}} -> {:error, r}
      {{:ok, _}, {:error, r}} -> {:error, r}
      {{:error, r}, {:error, _}} -> {:error, r}
    end
  end

  @doc """
  This is infix bind/2
  Has same syntax restrictions as pipe.
  ## Examples:
      def sgn(x) do
        if x > 0 do
          {:ok, "pos"}
        else
          {:error, "neg"}
        end
      end
      def two_args(x, y), do: {:ok, x - y}
      {:ok, 1}
      ~>> sgn
      = {:ok, "pos"}
      {:ok, -3}
      ~>> sgn
      = {:error, "neg"}
      {:error, 2}
      ~>> sgn
      = {:error, 2}
      {:ok, 3}
      ~>> two_args(2)
      = {:ok, 1}
  """
  # Hack: kind of a hack, i worry about throwing out the meta data - mostly line numbers.
  @doc updated: "0.1.1"
  @doc since: "0.1.0"
  @doc result: :base
  @spec t(a) ~>> (a -> t(b)) :: t(b)
  defmacro arg ~>> {{:., _fmeta, [fname]}, _meta, []} do
    quote do
      unquote(arg)
      |> unquote(__MODULE__).bind(unquote(fname))
    end
  end

  defmacro arg ~>> {fname, meta, params} when is_list(params) do
    quote do
      # reworks function calls with other arguments eg. fname(arg2) -> &(fname(&1, arg2))
      unquote(arg)
      |> unquote(__MODULE__).bind(&unquote({fname, meta, [{:&, [], [1]} | params]}))
    end
  end

  defmacro arg ~>> fun do
    quote do
      # wraps lone function name, eg. fname -> &fname/1
      unquote(arg)
      |> unquote(__MODULE__).bind(&(unquote(fun) / 1))
    end
  end

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
  @doc updated: "0.1.1"
  @doc since: "0.1.0"
  @doc result: :base
  @spec sequencing(t(a), t(b)) :: t(b)
  defmacro sequencing(ma, mb) do
    on_success_quoted =
      quote do
        case unquote(mb) do
          {:error, r} -> {:error, r}
          {:ok, val} -> {:ok, val}
          :ok -> :ok
        end
      end

    quote do
      ma = unquote(ma)

      case ma do
        {:error, _r} -> ma
        {:ok, _val} -> unquote(on_success_quoted)
        :ok -> unquote(on_success_quoted)
      end
    end
  end

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
  @doc since: "0.1.0"
  @doc result: :base
  @spec t(a) ~> t(b) :: t(b)
  defmacro ma ~> mb do
    quote do
      unquote(__MODULE__).sequencing(unquote(ma), unquote(mb))
    end
  end

  @doc """
  Applies the function to the value within the ok tuple or propogates error.
  ## Examples:
      iex> {:ok, 6}
      ...> |> fmap(fn x -> x+2 end)
      {:ok, 8}
      iex> {:error, 6}
      ...> |> fmap(fn x -> x+2 end)
      {:error, 6}
  """
  @doc since: "0.1.0"
  @doc result: :base
  @spec fmap(s(a), (a -> b)) :: s(b)
  def fmap(m, f), do: bind(m, &{:ok, f.(&1)})

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
  @doc since: "0.1.1"
  @doc result: :base
  @spec ignore(t(a)) :: p()
  def ignore(ma), do: sequencing(ma, :ok)

  @doc "Extracts the value or reason from the tuple."
  @doc since: "0.1.0"
  @doc result: :base
  @spec extract(s(a)) :: a
  def extract({:error, _} = ma) do
    raise ArgumentError, "`extract` expects an ok tuple, \"#{inspect(ma)}\" given."
  end

  def extract({:ok, value}), do: value

  @doc "Returns true if the given argument is an error tuple."
  @doc since: "0.1.0"
  @doc result: :base
  @spec is_error(t(a)) :: boolean
  def is_error({:error, _r}), do: true
  def is_error({:ok, _val}), do: false
  def is_error(:ok), do: false

  @doc "Returns true if the given argument is :ok, or an ok tuple."
  @doc since: "0.1.0"
  @doc result: :base
  @spec is_ok(t(a)) :: boolean
  def is_ok(ma), do: not is_error(ma)

  @doc "Flips an ok tuple to an error tuple and an error tuple to an ok tuple."
  @doc since: "0.1.0"
  @doc result: :helper
  @spec flip(s(a)) :: s(b)
  def flip({:error, r}), do: {:ok, r}
  def flip({:ok, v}), do: {:error, v}

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
  @doc updated: "0.1.1"
  @doc since: "0.1.0"
  @doc result: :helper
  @spec lift(a | b, b | (a | b -> boolean), c | (a | b -> c)) :: s(a)
  defmacro lift(val, p, f) do
    quote do
      p = unquote(p)
      val = unquote(val)
      # check if the value passes satisfies the predicate or matches the second argument.
      match = if is_function(p), do: p.(val), else: val == p

      if match do
        f = unquote(f)
        # lift to error tuple on match
        if(is_function(f), do: f.(val), else: f)
        |> unquote(__MODULE__).error
      else
        # ok tuple otherwise
        unquote(__MODULE__).ok(val)
      end
    end
  end

  @doc """
  Applies the function to the reason in an error tuple.
  Leaves success unchanged.
  ## Example:
      iex> account_name = "test"
      ...> {:error, :not_found}
      ...> |> map_error(fn r -> {r, account_name} end)
      {:error, {:not_found, "test"}}
  """
  @doc since: "0.1.0"
  @doc result: :helper
  @spec map_error(t(a), (any -> any)) :: t(a)
  def map_error({:error, r}, f), do: error(f.(r))
  def map_error({:ok, _val} = ma, _), do: ma
  def map_error(:ok, _), do: :ok

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
  @doc updated: "0.1.1"
  @doc since: "0.1.0"
  @doc result: :helper
  @spec mask_error(t(a), any) :: t(a)
  defmacro mask_error(ma, term) do
    quote do
      ma = unquote(ma)

      if unquote(__MODULE__).is_error(ma) do
        {:error, unquote(term)}
      else
        ma
      end
    end
  end

  @doc """
  Logs on error, does nothing on success.

  ## Example:
      {:error, :not_found}
      |> log_error("There was an error", level: :info, metadata: "some meta")
  """
  @doc updated: "0.1.1"
  @doc since: "0.1.0"
  @doc result: :helper
  # TODO: refine the type of second argument
  @spec log_error(t(a), String.t() | (any -> any), Keyword.t()) :: t(a)
  def log_error(ma, chardata_or_fun, opts \\ [])

  def log_error({:error, r} = ma, chardata_or_fun, opts) when is_binary(chardata_or_fun) do
    # default to :error level
    {level, metadata} = Keyword.pop(opts, :level, :error)

    log_fn =
      case level do
        :debug -> &Logger.debug/2
        :info -> &Logger.info/2
        :warn -> &Logger.warn/2
        :error -> &Logger.error/2
      end

    log_fn.(chardata_or_fun, [reason: "#{r}"] ++ metadata)

    ma
  end

  def log_error({:ok, _val} = ma, _, _), do: ma
  def log_error(:ok, _, _), do: :ok

  @doc """
  Binds the function to each tuple in the enum.
  ## Example:
      iex> [{:ok, 1}, {:ok, 2}, {:error, 3}, {:ok, 4}]
      ...> |> map_with_bind(fn x -> if x == 2, do: {:error, x*6}, else: {:ok, x*6} end)
      [{:ok, 6}, {:error, 12}, {:error, 3}, {:ok, 24}]
  """
  @doc since: "0.1.0"
  @doc result: :mapper
  @spec map_with_bind(Enum.t(s(a)), (a -> s(b))) :: Enum.t(s(b))
  def map_with_bind(l, f), do: Enum.map(l, &bind(&1, f))

  @doc """
  Converts a matching error to :ok
  An error matches if the reason is equal to the supplied atom or the reason passes the predicate.
  Leaves success and other errors unchanged.
  ## Examples:
      iex> {:error, :already_completed}
      ...> |> convert_error(:already_completed)
      :ok
      iex> {:error, :already_completed}
      ...> |> convert_error(fn r -> r == :already_completed end)
      :ok
  """
  @doc updated: "0.1.1"
  @doc since: "0.1.0"
  @doc result: :helper
  # Note: convert_error/2 is eager and that's fine.
  @spec convert_error(t(a), (any -> boolean) | any) :: t(a)
  def convert_error({:error, r} = ma, p) when is_function(p) do
    if p.(r), do: :ok, else: ma
  end

  def convert_error({:error, r} = ma, term) do
    if r == term, do: :ok, else: ma
  end

  def convert_error({:ok, _val} = ma, _p), do: ma
  def convert_error(:ok, _p), do: :ok

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
  @doc updated: "0.1.1"
  @doc since: "0.1.0"
  @doc result: :helper
  @spec convert_error(t(a), (any -> boolean) | any, b | (any -> t(b))) :: t(b)
  defmacro convert_error(ma, p, f) do
    quote do
      ma = unquote(ma)
      p = unquote(p)

      case ma do
        {:error, r} ->
          match = if is_function(p), do: p.(r), else: r == p

          if match do
            f = unquote(f)
            # convert to ok tuple with new value.
            if is_function(f), do: f.(r), else: {:ok, f}
          else
            ma
          end

        {:ok, _v} ->
          ma

        :ok ->
          ma
      end
    end
  end

  @doc """
  Given an enumerable of plain values,
  it returns {:ok, processed enum} or the first error.
  Equivalent to traverse or mapM in Haskell.
  ## Examples
      iex> [1, 2, 3, 4]
      ...> |> map_while_success(fn x -> if x == 3 || x == 1, do: {:error, x}, else: {:ok, x} end)
      {:error, 1}
      iex> map_while_success([1, 2, 3, 4], fn x -> {:ok, x + 2} end)
      {:ok, [3, 4, 5, 6]}
  """
  @doc since: "0.1.0"
  @doc result: :mapper
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
  Given a list of tuples, it returns the first error
  or ok tuple containing an enum of all the extracted values.
  ## Examples:
      iex> [{:ok, 1}, {:error, 2}, {:error, 3}, {:ok, 4}]
      ...> |> sequence
      {:error, 2}
      iex> [{:ok, 1}, {:ok, 2}, {:ok, 3}, {:ok, 4}]
      ...> |> sequence
      {:ok, [1, 2, 3, 4]}
  """
  @doc since: "0.1.0"
  @doc result: :mapper
  @spec sequence(Enum.t(s(a))) :: s(Enum.t(a))
  def sequence(ms), do: map_while_success(ms, & &1)

  @doc """
  Given an enum of tuples, an initial value, and a reducing function, it returns the first error
  or reduced result.
  ## Examples:
      iex> [{:ok, 1}, {:ok, 2}, {:ok, 3}, {:ok, 4}]
      ...> |> reduce_unless_error({:ok, 100}, &{:ok, &1  + &2})
      {:ok, 110}
      iex> [{:ok, 1}, {:error, 2}, {:ok, 3}, {:error, 4}]
      ...> |> reduce_unless_error({:ok, 100}, &{:ok, &1 + &2})
      {:error, 2}
  """
  @doc since: "0.1.0"
  @doc result: :mapper
  @spec reduce_unless_error(Enum.t(s(a)), s(a), (a, b -> s(b))) :: s(b)
  def reduce_unless_error(ms, b, f) do
    Enum.reduce_while(ms, b, fn ma, acc ->
      case bind(ma, acc, f) do
        {:ok, val} -> {:cont, {:ok, val}}
        {:error, r} -> {:halt, {:error, r}}
      end
    end)
  end

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
  @doc since: "0.1.0"
  @doc result: :mapper
  # Note: this is what Enum.reduce/2 does on 0 and 1 element lists. Is it type safe? not at all
  @spec reduce_unless_error(Enum.t(s(a)), (a, b -> s(b))) :: s(b) | s(a)
  def reduce_unless_error(ms, f) do
    case ms do
      [] -> raise Enum.EmptyError
      [x] -> x
      [x | xs] -> reduce_unless_error(xs, x, f)
    end
  end

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
  @doc since: "0.1.0"
  @doc result: :mapper
  @spec stop_at_first_error(Enum.t(t(a))) :: t(a)
  def stop_at_first_error(ms) do
    Enum.reduce_while(ms, :ok, fn ma, _acc ->
      case ma do
        :ok -> {:cont, :ok}
        {:ok, _v} -> {:cont, ma}
        {:error, _r} -> {:halt, ma}
      end
    end)
  end

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
  @doc since: "0.1.1"
  @doc result: :mapper
  @spec each_while_success(Enum.t(a), (a -> p())) :: p()
  def each_while_success(ms, f) do
    Enum.reduce_while(ms, :ok, fn x, _acc ->
      case f.(x) do
        :ok -> {:cont, :ok}
        {:error, r} -> {:halt, {:error, r}}
      end
    end)
  end

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
  @doc since: "0.1.0"
  @doc result: :mapper
  @spec filter(Enum.t(s(a)), (a -> boolean)) :: t(Enum.s(a))
  def filter(ms, p) do
    ms
    |> Enum.reduce({:ok, []}, fn x, acc ->
      case fmap(x, p) do
        {:ok, true} -> bind(x, acc, &{:ok, [&1 | &2]})
        {:ok, false} -> acc
        {:error, _r} -> acc
      end
    end)
    |> fmap(&Enum.reverse/1)
  end
end
