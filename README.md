# Overview

If there’s a success continue, if there’s an error propagate it.

Monadic Error Handling - but that's not all.

This library distiguishes itself from other result monad libraries like OK[link] by providing functions for modifying the unhappy path and for interacting with Enums.

- not an academic project, this library is in use at the enterprise level
- doesn't over haskellize
  - while pure functional programming has definitely inspired this library, it tries to stay true to it's elixir roots. We like the  `with` statement and don't wish to abolish it. We prefer explicit code to magical macros or custom structures. These tools are meant to facilitate writing readable exiliry code rather than creating a subdialect of elixir or a DSL.

## Types

Parametrized types
```elixir
  @type s(x) :: {:ok, x} | {:error, any}
  @type t(x) :: :ok | s(x)
```

Convienence types
```elixir
  @type p() :: :ok | {:error, any}
  @type s() :: s(any)
  @type t() :: t(any)
```

**Style Recommendation**
Specs and Callbacks. It's recommended that you write specs for your functions usings these shorthands.

```elixir
@spec my_fun({:ok, String.t} | {:error, any}, Integer) :: :ok | {:error, any}
```

```elixir
@spec my_fun(Result.s(String.t), Integer) :: Result.p()
```
## Base

In base:

Use `ok/1` to wrap a value in an ok tuple.
(Discouraged for all `ok` tuples. Best for the final action in a pipe chain.)

```elixir
  iex> 2
  ...> |> ok
  {:ok, 2}
```

```elixir
  iex> :not_found
  |> error
  {:error, :not_found}
```

**Style Recommendation**
Only use `ok/1` and `error/1` at the end of pipe chains. While they can be used directly or in case patterns,
the tuple syntax is more explicit and no more cumbersome in those events.

Error is unchanged.

```elixir
iex> {:ok, 2}
|> fmap( fn x -> x + 5 end)
{:ok, 7}

iex> {:error, :not_found}
|> fmap(fn x, 5 -> x + 5 end)
{:error, :not_found}
```

```elixir
iex> {:ok, 2}
|> bind(fn x -> if x > 0, do: {:ok, x + 5}, else: {:error, :neg})
{:ok, 7}

iex> {:ok, -1}
|> bind(fn x -> if x > 0, do: {:ok, x + 5}, else: {:error, :neg})
{:error, :neg}

iex> {:error, :not_found}
|> bind(fn x -> if x > 0, do: {:ok, x + 5}, else: {:error, :neg})
{:error, :not_found}

```


**Style Recommendation**
use `~>` in a pipe chain when the function argument is named and short (one line). If the function argument is anonymous use `|> bind`. When only a single `~>` is needed just use prefix bind in normal form, avoid the single `~>`.

## Helpers

These are functions to deal with the unhappy path, when errors are returned. Other libraries provide no way to change these in pipe format.

Always propagates the success path. Is fine with `:ok` as a success value.

```elixir
iex> {:error, 404}
|> map_error(fn reason -> {:invalid_response, reason} end)
{:error, {:invalid_reponse, 404}}

iex> {:ok, 2}
|> map_error(fn reason -> {:invalid_response, reason} end)
{:ok, 2}

iex> :ok
|> map_error(:ok, fn reason -> {:invalid_response, reason} end)
:ok
```

```elixir
iex> {:error, :not_found}
|> mask_error(:failure)
{:error, :failure}
```

```elixir
iex> {:error, :not_found}
|> convert_error(:not_found)
:ok

iex> {:error, :not_found}
|> convert_error(:not_found, default)
{:ok, default}
```

Automatically includes the reason in the log metadata.

```elixir
iex> {:error, :not_found}
|> log_error("There was a problem", level: :warn)
{:error, :not_found}
```

Also some are provided to enter the monadic scope:

If the value matches the predicate then it is lifted into an error tuple and it's reason replaced by the 3rd argument.

```elixir
iex> :error
|> normalize_error(:not_found)
{:error, :not_found}

iex> {:ok, 2}
|> normalize_error(:not_found)
{:ok, 2}

iex> :ok
|> normalize_error(:not_found)
:ok
```

```elixir
iex> nil
|> lift(nil, :not_found)
{:error, :not_found}

iex> 2
|> lift(nil, :not_found)
{:ok, 2}
```

## Mappers

```elixir

`map_while_success/2` `each_while_success/2` `reduce_while_success/3` all mimic the Enum functions `Enum.map/2, `Enum.each/2`, `Enum.reduce/3`

```


Other functions exist which aren't listed.
### Getting Started

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `result` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:result, "~> 0.1.3"}
  ]
end
```

## Usage

`use Result` to import all 3 modules.

or `import Result.*` to import individually


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/result](https://hexdocs.pm/result).