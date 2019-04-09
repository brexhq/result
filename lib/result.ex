defmodule Result do
  @moduledoc """
  A library to handle error and success results and propagation.
      :ok | {:ok, val} | {:error, reason}
  Similar to the Either Monad in Haskell

  Result builds upon four building blocks:
  - `Result.Base` - Tools for doing basic `ok`/`error` tuple manipulations.
  - `Result.Helpers` - Tools for dealing with the unhappy path. `Error` tuple manipulations.
  - `Result.Mappers` - Tools for combining `Enum` and `ok`/`error` tuples.

  """
  @moduledoc since: "0.1.3"

  alias Result.Base

  @type s(x) :: Base.s(x)
  @type t(x) :: Base.t(x)

  @type p() :: Base.p()
  @type s() :: Base.s()
  @type t() :: Base.t()

  @version Mix.Project.config()[:version]

  def version, do: @version

  # Review: This is how exceptional https://github.com/expede/exceptional/tree/master/lib and some other libraries format their lib.
  # Not sure if the using macro is super useful.

  defmacro __using__(_opts) do
    quote do
      import Result.Base
      import Result.Helpers
      import Result.Mappers
    end
  end
end
