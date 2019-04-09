# Result

TODO: fill in

## The Types


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
  :not_found
  |> error
  {:error, :not_found}
```

**Style Recommendation**
Only use `ok/1` and `error/1` at the end of pipe chains. While they can be used directly or in case patterns,
the tuple syntax is more explicit and no more cumbersome in those events.

```elixir
  fmap({:ok, 2}, )

  fmap({:error, :not_found}, )
```

```elixir

bind, ~>

```


**Style Recommendation**


## Helpers

```elixir
```

```elixir
```

```elixir
```

```elixir
```

## Mappers

```elixir
```

```elixir
```

```elixir
```

### Getting Started

If there’s a success continue, if there’s an error propagate it.

`use Result` to import all 3 modules.

or `import Result.*` to import individually


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

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/result](https://hexdocs.pm/result).
