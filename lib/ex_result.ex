defmodule ExResult do
  @moduledoc """
  This library provides tools to handle three common return values in Elixir

      :ok | {:ok, value} | {:error, reason}

  `ExResult` is split into three main components:

  - `ExResult.Base` - Base provides tools for creating and passing around `ok`/`error` tuples.
    The tools follow the property: if there’s a success continue the computation, if there’s an error propagate it.
  - `ExResult.Helpers` - Helpers includes tools for modifying the reason in `error` tuples.
    The functions in this module always propogate the success value.
  - `ExResult.Mappers` - Mappers includes tools for applying functions that return
    `:ok | {:ok, val} | {:error, reason}` over `Enumerables`.

  To import the entire library:
      use ExResult
  To import the modules individually:
      import ExResult.Base
      import ExResult.Helpers
      import ExResult.Mappers

  """
  @moduledoc since: "0.1.3"

  alias ExResult.Base

  @type s(x) :: Base.s(x)
  @type t(x) :: Base.t(x)

  @type p() :: Base.p()
  @type s() :: Base.s()
  @type t() :: Base.t()

  @version Mix.Project.config()[:version]

  @doc false
  def version, do: @version

  defmacro __using__(_opts) do
    quote do
      import ExResult.Base
      import ExResult.Helpers
      import ExResult.Mappers
    end
  end
end
