defmodule Brex.Result.Helpers do
  @moduledoc """
  Tools for modifying the reason in `error` tuples.
  """

  import Brex.Result.Base
  alias Brex.Result.Base

  require Logger

  @typep a :: any()
  @typep b :: any()
  @typep c :: any()

  @type s(x) :: Base.s(x)
  @type t(x) :: Base.t(x)

  @type p() :: Base.p()
  @type s() :: Base.s()
  @type t() :: Base.t()

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
  @doc since: "0.1.2"
  @spec normalize_error(any, any) :: t()
  def normalize_error(x, reason \\ :normalized) do
    case x do
      :error -> {:error, reason}
      {:error, _r} -> x
      {:ok, _val} -> x
      :ok -> :ok
    end
  end

  @doc """
  Lifts a value into a success tuple unless:
  1) the value matches the second argument
  2) when applied to the value, the second argument function returns `true`

  In those cases an `error` tuple is returned with either
  1) the third argument as the reason
  2) the third argument function applied to the value, as the reason

  `lift/3` is lazy, this means third argument will only be evaluated when necessary.

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
        {:error, if(is_function(f), do: f.(val), else: f)}
      else
        # ok tuple otherwise
        {:ok, val}
      end
    end
  end

  @doc """
  Applies the function to the reason in an `error` tuple.
  Leaves success unchanged.

  ## Example:

      iex> account_name = "test"
      ...> {:error, :not_found}
      ...> |> map_error(fn r -> {r, account_name} end)
      {:error, {:not_found, "test"}}

  """
  @doc since: "0.1.0"
  @spec map_error(t(a), (any -> any)) :: t(a)
  def map_error({:error, r}, f), do: error(f.(r))
  def map_error({:ok, _val} = ma, _), do: ma
  def map_error(:ok, _), do: :ok

  @doc """
  Replaces the reason in an `error` tuple.
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
  @spec mask_error(t(a), any) :: t(a)
  defmacro mask_error(ma, term) do
    quote do
      case unquote(ma) do
        {:error, _} -> {:error, unquote(term)}
        {:ok, val} -> {:ok, val}
        :ok -> :ok
      end
    end
  end

  @doc """
  Logs on `error`, does nothing on success.

  ## Example:

      {:error, :not_found}
      |> log_error("There was an error", level: :info, metadata: "some meta")

  """
  @doc updated: "0.1.1"
  @doc since: "0.1.0"
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
  Converts a matching error to `:ok`
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

  ## Examples:

      iex> {:error, :already_completed}
      ...> |> convert_error(:already_completed, "submitted")
      {:ok, "submitted"}

      iex> {:error, "test"}
      ...> |> convert_error(&(&1 == "test"), fn r -> {:ok, r <> "ed"} end)
      {:ok, "tested"}

  """
  @doc updated: "0.1.1"
  @doc since: "0.1.0"
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
end
