defmodule ExResult do
  @moduledoc """
   # TODO
  A library to handle error and success results and propagation.
      :ok | {:ok, val} | {:error, reason}
  Similar to the Either Monad in Haskell

  ExResult builds upon three building blocks:
  - `ExResult.Base` - Tools for doing basic `ok`/`error` tuple manipulations.
  - `ExResult.Helpers` - Tools for dealing with the unhappy path. `Error` tuple manipulations.
  - `ExResult.Mappers` - Tools for combining `Enum` and `ok`/`error` tuples.

  """
  @moduledoc since: "0.1.3"

  alias ExResult.Base

  @type s(x) :: Base.s(x)
  @type t(x) :: Base.t(x)

  @type p() :: Base.p()
  @type s() :: Base.s()
  @type t() :: Base.t()

  @version Mix.Project.config()[:version]

  def version, do: @version

  defmacro __using__(_opts) do
    quote do
      import ExResult.Base
      import ExResult.Helpers
      import ExResult.Mappers
    end
  end
end
