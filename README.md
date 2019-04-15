# ExResult

This library provides tools to handle three common return values in Elixir
    :ok | {:ok, value} | {:error, reason}

## Overview

ExResult is split into three main components:

- `ExResult.Base` - Base provides tools for doing basic `ok`/`error` tuple manipulations. The tools there follow the property: if the value given is a success value, apply the function, otherwise propogate the error.
If there’s a success continue, if there’s an error propagate it.
 They provide tools to build the happy path.
- `ExResult.Helpers` - Helpers includes tools for manipulating `error tuples`. Convience functions for handling the unhappy path.
- `ExResult.Mappers` - Mappers includes tools for applying functions that return `:ok | {:ok, val} | {:error, reason}` over `Enumerables`.

Include the line `use ExResult` to import the entire library or `import ExResult.{Base, Helpers, Mappers}` to import the modules individually.

## Differences from Similar Libraries
There are some other libraries that concept of monadic error handling.
[OK](https://github.com/CrowdHailer/OK)

ExResult separates itself by:

- Extending support beyond classic monadic functions
  - support for `:ok` as a success value
  - support for modifying `errors`
  - support for mapping functions that return `ok | {:ok, value} | {:error, reason}` over `enumerables`
- Staying true to elixir roots
  - encourages use of elixir builtins like the `with` statement when appropriate
  - provides style guidelines
  - actively avoids heavy macro magic that can turn a library into a DSL

## Definitions

- **Ok/Error tuples**:`{:ok, value} | {:error, reason}`
- **Error tuples**: `{:error, reason}`
- **OK/Success tuples**: `{:ok, value}`
- **Success values**: `:ok | {:ok, value}`
- **Happy path**: The path of code execution where each ___ is successful.
- **Unhappy path**: The path of code execution where errors are encountered. Once you have an error, how do you deal with it.

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

It is recommended that you write specs and callbacks usings these shorthands.

```elixir
@spec my_fun({:ok, String.t} | {:error, any}, Integer) :: :ok | {:error, any}
```

```elixir
@spec my_fun(Result.s(String.t), Integer) :: Result.p()
```

## Base

Use `ExResult.Base.ok/1` to wrap a value in an `ok` tuple.

```elixir
  iex> 2
  ...> |> ok
  {:ok, 2}
```

`ExResult.Base.error/1` wraps a value in an `error` tuple.

```elixir
  iex> :not_found
  ...> |> error
  {:error, :not_found}
```

#### Style Recommendation

Only use `ok/1` and `error/1` at the end of pipe chains. While they can be used directly or in case patterns, the tuple syntax is more explicit and no more cumbersome in those events.

```elixir
 # No
  ok(2)

# Yes
  {:ok, 2}

# No
  val =
    arg
    |> get_values()
    |> transform(other_arg)

{:ok, val}

# Yes
  arg
  |> get_values()
  |> transform(other_arg)
  |> ok
```


Error is unchanged.

```elixir
iex> {:ok, 2}
...> |> fmap(fn x -> x + 5 end)
{:ok, 7}

iex> {:error, :not_found}
...> |> fmap(fn x, 5 -> x + 5 end)
{:error, :not_found}
```

```elixir
iex> {:ok, 2}
...> |> bind(fn x -> if x > 0, do: {:ok, x + 5}, else: {:error, :neg})
{:ok, 7}

iex> {:ok, -1}
...> |> bind(fn x -> if x > 0, do: {:ok, x + 5}, else: {:error, :neg})
{:error, :neg}

iex> {:error, :not_found}
...> |> bind(fn x -> if x > 0, do: {:ok, x + 5}, else: {:error, :neg})
{:error, :not_found}

```

#### Style Recommendation

Avoid single `~>`s and only use `~>` when the function argument is named and fits onto one line.

```elixir
# No
{:ok, file}
~> File.read

# Yes
bind({:ok, file}, &File.read/1)

# No
{:ok, val}
~> (fn x -> if x > 0, do: {:ok, x}, else: {:error, neg}).()
~> insert_amount

# Yes
{:ok, val}
|> bind(fn x -> if x > 0, do: {:ok, x}, else: {:error, neg})
~> insert_amount
```

## Helpers

These are functions to deal with the unhappy path, when errors are returned. Other libraries provide no way to change these in pipe format.

Always propagates the success path. Is fine with `:ok` as a success value.

```elixir
iex> {:error, 404}
...> |> map_error(fn reason -> {:invalid_response, reason} end)
{:error, {:invalid_reponse, 404}}

iex> {:ok, 2}
...> |> map_error(fn reason -> {:invalid_response, reason} end)
{:ok, 2}

iex> :ok
...> |> map_error(fn reason -> {:invalid_response, reason} end)
:ok
```

```elixir
iex> {:error, :not_found}
...> |> mask_error(:failure)
{:error, :failure}
```

```elixir
iex> {:error, :not_found}
...> |> convert_error(:not_found)
:ok

iex> {:error, :not_found}
...> |> convert_error(:not_found, default)
{:ok, default}
```

Automatically includes the reason in the log metadata.

```elixir
iex> {:error, :not_found}
...> |> log_error("There was a problem", level: :warn)
{:error, :not_found}
```

Also some are provided to enter the monadic scope:



```elixir
iex> :error
...> |> normalize_error(:not_found)
{:error, :not_found}

iex> {:ok, 2}
...> |> normalize_error(:not_found)
{:ok, 2}

iex> :ok
...> |> normalize_error(:not_found)
:ok
```

If the value matches the predicate then it is lifted into an error tuple and it's reason replaced by the 3rd argument.

```elixir
iex> nil
...> |> lift(nil, :not_found)
{:error, :not_found}

iex> 2
...> |> lift(nil, :not_found)
{:ok, 2}
```

## Mappers

Plain values
`ExResult.Mappers.map_while_success/2`, `ExResult.Mappers.each_while_success/2`, `ExResult.Mappers.reduce_while_success/3` all mimic the Enum functions `Enum.map/2`, `Enum.each/2`, `Enum.reduce/3`


Other functions exist which aren't listed.
See the examples folder for more intense examples.

## Known Problems

- Incorrect specs on macros according to dialyzer, but they are very useful in documentation.
- Credo complains pipe chain is not started with raw value when preceeded by `~>`.

## Installation

The package can be installed by adding `ex_result` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_result, "~> 0.1.3"}
  ]
end
```

Docs can be found at [https://hexdocs.pm/ex_result](https://hexdocs.pm/ex_result).