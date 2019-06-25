defmodule Brex.Result do
  @moduledoc """
  This library provides tools to handle three common return values in Elixir

      :ok | {:ok, value} | {:error, reason}

  `Brex.Result` is split into three main components:

  - `Brex.Result.Base` - Base provides tools for creating and passing around `ok`/`error` tuples.
    The tools follow the property: if there’s a success continue the computation, if there’s an error propagate it.
  - `Brex.Result.Helpers` - Helpers includes tools for modifying the reason in `error` tuples.
    The functions in this module always propagate the success value.
  - `Brex.Result.Mappers` - Mappers includes tools for applying functions that return
    `:ok | {:ok, val} | {:error, reason}` over `Enumerables`.

  To import the entire library:
      use Brex.Result
  To import the modules individually:
      import Brex.Result.Base
      import Brex.Result.Helpers
      import Brex.Result.Mappers

  """
  @moduledoc since: "0.4.0"

  alias Brex.Result.Base

  @typedoc "`{:ok, x} | {:error, any}`"
  @type s(x) :: Base.s(x)
  @typedoc "`:ok | {:ok, x} | {:error, any}`"
  @type t(x) :: Base.t(x)
  @typedoc "`:ok | {:error, any}`"
  @type p() :: Base.p()
  @typedoc "`{:ok, any} | {:error, any}`"
  @type s() :: Base.s()
  @typedoc "`:ok | {:ok, any} | {:error, any}`"
  @type t() :: Base.t()

  @version Mix.Project.config()[:version]

  @doc false
  def version, do: @version

  defmacro __using__(_opts) do
    quote do
      import Brex.Result.Base
      import Brex.Result.Helpers
      import Brex.Result.Mappers
    end
  end
end
