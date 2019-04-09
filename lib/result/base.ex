defmodule Brex.Result.Base do
  @moduledoc """
  Tools for doing basic result tuple manipulations.
  """

  @typep a :: any()
  @typep b :: any()

  @type s(x) :: {:ok, x} | {:error, any}
  @type t(x) :: :ok | s(x)

  @type p() :: :ok | {:error, any}
  @type s() :: s(any)
  @type t() :: t(any)

  @doc """
  Wraps value in an `ok` tuple.
  Will be inlined at compile time.
  """
  @doc since: "0.1.0"
  @spec ok(a) :: s(a)
  defmacro ok(val), do: {:ok, val}

  @doc """
  Wraps value in an `error` tuple
  Will be inlined at compile time.
  """
  @doc since: "0.1.0"
  @spec error(any) :: t(a)
  defmacro error(r), do: {:error, r}

  @doc """
  Takes in a tuple and function from plain value to `{:ok, any} | {:error, any}`.
  Applies the function to the value within the `ok` tuple or propogates the `error`.

  ## Examples:

      iex> bind({:ok, 1}, fn x -> if x == 1, do: {:ok, 2}, else: {:error, "not_one"} end)
      {:ok, 2}

      iex> bind({:ok, 4}, fn x -> if x == 1, do: {:ok, 2}, else: {:error, "not_one"} end)
      {:error, "not_one"}

      iex> bind({:error, 4}, fn x -> if x == 1, do: {:ok, 2}, else: {:error, "not_one"} end)
      {:error, 4}

  """
  @doc updated: "0.1.2"
  @doc since: "0.1.0"
  @spec bind(s(a), (a -> s(b))) :: s(b)
  def bind({:error, r}, _), do: {:error, r}

  def bind({:ok, v}, f) do
    case f.(v) do
      {:error, r} -> {:error, r}
      {:ok, val} -> {:ok, val}
    end
  end

  @doc """
  This is infix `bind/2`
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
      ~> sgn
      = {:ok, "pos"}

      {:ok, -3}
      ~> sgn
      = {:error, "neg"}

      {:error, 2}
      ~> sgn
      = {:error, 2}

      {:ok, 3}
      ~> two_args(2)
      = {:ok, 1}

  """
  @doc updated: "0.1.3"
  @doc since: "0.1.0"
  @spec t(a) ~> (a -> t(b)) :: t(b)
  defmacro arg ~> fun do
    quote do
      unquote(__MODULE__).bind(unquote(arg), fn x ->
        x
        |> unquote(fun)
      end)
    end
  end

  @doc """
  Takes in a tuple and a function from plain value to plain value.
  Applies the function to the value within the `ok` tuple or propogates `error`.

  ## Examples:

      iex> {:ok, 6}
      ...> |> fmap(fn x -> x+2 end)
      {:ok, 8}

      iex> {:error, 6}
      ...> |> fmap(fn x -> x+2 end)
      {:error, 6}

  """
  @doc since: "0.1.0"
  @spec fmap(s(a), (a -> b)) :: s(b)
  def fmap(m, f), do: bind(m, &{:ok, f.(&1)})

  @doc """
  Ignores the value in an `ok` tuple and just returns `:ok`.
  Still shortcircuits on `error`.

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
  @spec ignore(t(a)) :: p()
  def ignore({:error, r}), do: {:error, r}
  def ignore({:ok, _val}), do: :ok
  def ignore(:ok), do: :ok

  @doc """
    Extracts the value or reason from the tuple.
    Caution: If given an `error` tuple it raise an exception!
  """
  @doc updated: "0.1.2"
  @doc since: "0.1.0"
  @spec extract!(s(a)) :: a
  def extract!({:error, _} = ma) do
    raise ArgumentError, "`extract` expects an ok tuple, \"#{inspect(ma)}\" given."
  end

  def extract!({:ok, value}), do: value
end
