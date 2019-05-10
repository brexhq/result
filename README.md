# Brex.Result

![](https://raw.githubusercontent.com/brexhq/result/master/Brex.Result.png)

[![Build Status](https://travis-ci.org/brexhq/result.svg?branch=master)](https://travis-ci.org/brexhq/result)
[![hex.pm version](https://img.shields.io/hexpm/v/brex_result.svg)](https://hex.pm/packages/brex_result)
[![Coverage Status](https://coveralls.io/repos/github/brexhq/result/badge.svg?branch=master)](https://coveralls.io/github/brexhq/result?branch=master)
[![license](https://img.shields.io/github/license/brexhq/result.svg)](https://github.com/brexhq/result/blob/master/LICENSE)

This library provides tools to handle three common return values in Elixir

```elixir
:ok | {:ok, value} | {:error, reason}
```

## Table of Contents

- [Overview](#overview)
- [Usage](#usage)
- [Differences rom Similar Libraries](#differences-from-similar-libraries)
- [Definitions](#definitions)
- [Types](#types)
- [Base](#base)
- [Helpers](#helpers)
- [Mappers](#mappers)
- [Known Problems](#known-problems)
- [Installation](#installation)

## Overview

`Brex.Result` is split into three main components:

- `Brex.Result.Base` - Base provides tools for creating and passing around `ok`/`error` tuples. The tools follow the property: if there’s a success continue the computation, if there’s an error propagate it.
- `Brex.Result.Helpers` - Helpers includes tools for modifying the reason in `error` tuples. The functions in this module always propogate the success value.
- `Brex.Result.Mappers` - Mappers includes tools for applying functions that return `:ok | {:ok, val} | {:error, reason}` over `Enumerables`.

## Usage

Include the line `use Brex.Result` to import the entire library or `import Brex.Result.{Base, Helpers, Mappers}` to import the modules individually.

A sampling of functions and examples are provided below. For more in-depth examples see [examples](https://github.com/brexhq/result/tree/master/examples).

## Differences from Similar Libraries

Other libraries like [OK](https://github.com/CrowdHailer/OK), [Monad](https://github.com/rmies/monad), and [Ok Jose](https://github.com/vic/ok_jose) have embraced the concept of monadic error handling and have analogous functions to the ones we have in `Brex.Result.Base`.

`Brex.Result` separates itself by:

- Extending support beyond classic monadic functions
  - support for `:ok` as a success value
  - support for modifying `errors` tuple reasons
  - support for mapping functions that return `ok | {:ok, value} | {:error, reason}` over `enumerables`
- Respecting Elixir idioms
  - encourages use of elixir builtins like the `with` statement when appropriate
  - provides style guidelines
  - actively avoids heavy macro magic that can turn a library into a DSL

## Definitions

- **Result tuples**:`{:ok, value} | {:error, reason}`
- **Error tuples**: `{:error, reason}`
- **OK/Success tuples**: `{:ok, value}`
- **Success values**: `:ok | {:ok, value}`
- **Propagate a value**: Return a value unchanged

## Types

Parametrized types

```elixir
@type s(x) :: {:ok, x} | {:error, any}
@type t(x) :: :ok | s(x)
```

Convenience types

```elixir
@type p() :: :ok | {:error, any}
@type s() :: s(any)
@type t() :: t(any)
```

#### Style Recommendation

Write specs and callbacks usings these shorthands.

```elixir
# Original
@spec my_fun({:ok, String.t} | {:error, any}, Integer) :: :ok | {:error, any}

# With shorthands
@spec my_fun(Brex.Result.s(String.t), Integer) :: Brex.Result.p()
```

## Base

Use `Brex.Result.Base.ok/1` to wrap a value in an `ok` tuple.

```elixir
iex> 2
...> |> ok
{:ok, 2}
```

`Brex.Result.Base.error/1` wraps a value in an `error` tuple.

```elixir
iex> :not_found
...> |> error
{:error, :not_found}
```

#### Style Recommendation

_Don't_ use `ok/1` and `error/1` when tuple syntax is more explicit:

```elixir
# No
ok(2)

# Yes
{:ok, 2}
```

_Do_ use `ok/1` and `error/1` at the end of a chain of pipes:

```elixir
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

Use `Brex.Result.Base.fmap/2` to transform the value within a success tuple. It propogates the error value.

```elixir
iex> {:ok, 2}
...> |> fmap(fn x -> x + 5 end)
{:ok, 7}

iex> {:error, :not_found}
...> |> fmap(fn x -> x + 5 end)
{:error, :not_found}
```

Use `Brex.Result.Base.bind/2` to apply a function to the value within a success tuple. The function _must_ returns a result tuple.

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

Infix bind is given for convience as `Brex.Result.Base.~>/2`

```elixir
iex> {:ok, [[1, 2, 3, 4]}
...> ~> Enum.member(2)
...> |> fmap(fn x -> if x, do: :found_two, else: :not_found end)
{:ok, :found_two}
```

#### Style Recommendation

Avoid single `~>`s and only use `~>` when the function argument is named and fits onto one line.

```elixir
# No
{:ok, file}
~> File.read()

# Yes
bind({:ok, file}, &File.read/1)

# No
{:ok, val}
~> (fn x -> if x > 0, do: {:ok, x}, else: {:error, neg}).()
~> insert_amount()

# Yes
{:ok, val}
|> bind(fn x -> if x > 0, do: {:ok, x}, else: {:error, neg})
~> insert_amount()
```

## Helpers

`Brex.Result.Helpers.map_error/2` allows you to transform the reason in an `error` tuple.

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

`Brex.Result.Helpers.mask_error/2` disregards the current reason and replaces it with the second argument.

```elixir
iex> {:error, :not_found}
...> |> mask_error(:failure)
{:error, :failure}
```

`Brex.Result.Helpers.convert_error/3` converts an `error` into a success value if the reason matches the second argument.

```elixir
iex> {:error, :not_found}
...> |> convert_error(:not_found)
:ok

iex> {:error, :not_found}
...> |> convert_error(:not_found, default)
{:ok, default}
```

`Brex.Result.Helpers.log_error/3` logs on error. It automatically includes the reason in the log metadata.

```elixir
iex> {:error, :not_found}
...> |> log_error("There was a problem", level: :warn)
{:error, :not_found}
```

`Brex.Result.Helpers.normalize_error/2` converts a naked `:error` atom into an `error` tuple. It's good for functions from outside libraries.

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

## Mappers

`Brex.Result.Mappers.map_while_success/2`, `Brex.Result.Mappers.each_while_success/2`, `Brex.Result.Mappers.reduce_while_success/3` all mimic the Enum functions `Enum.map/2`, `Enum.each/2`, `Enum.reduce/3`, but take a function that returns `:ok | {:ok, value} | {:error, reason}` as the mapping/reducing argument. Each of these functions produce a success value containing the final result or the first `error`.

## Known Problems

- Credo complains pipe chain is not started with raw value when preceeded by `~>`.

## Installation

The package can be installed by adding `brex_result` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:brex_result, "~> 0.4.1"}
  ]
end
```
