defmodule MappersTest do
  @moduledoc false
  use ExUnit.Case

  import ExResult.Mappers

  doctest ExResult.Mappers

  test "map_with_bind" do
    assert [{:ok, 6}, {:error, 12}, {:error, 3}, {:ok, 24}] =
             [{:ok, 1}, {:ok, 2}, {:error, 3}, {:ok, 4}]
             |> map_with_bind(fn x -> if x == 2, do: {:error, x * 6}, else: {:ok, x * 6} end)
  end

  test "map_while_success" do
    assert {:error, 1} =
             [1, 2, 3, 4]
             |> map_while_success(fn x -> if x == 3 || x == 1, do: {:error, x}, else: {:ok, x} end)

    assert {:ok, [3, 4, 5, 6]} = map_while_success([1, 2, 3, 4], fn x -> {:ok, x + 2} end)
  end

  test "reduce_while_success/3" do
    # Note: the order is wacky
    assert {:ok, "dcbae"} =
             ["a", "b", "c", "d"]
             |> reduce_while_success({:ok, "e"}, &{:ok, &1 <> &2})

    assert {:error, "test"}

    ["a", "b", "c", "d"]
    |> reduce_while_success({:error, "test"}, &{:ok, &1 <> &2})

    assert {:error, "B!"} =
             ["a", "b", "c", "d"]
             |> reduce_while_success(
               {:ok, "e"},
               fn x, acc -> if x == "b", do: {:error, "B!"}, else: {:ok, x <> acc} end
             )
  end

  test "each_while_success" do
    assert {:error, :too_big} =
             [1, 2, 3, 4]
             |> each_while_success(fn x -> if x < 3, do: :ok, else: {:error, :too_big} end)

    assert :ok =
             [1, 2, 3, 4]
             |> each_while_success(fn x -> if x < 5, do: :ok, else: {:error, :too_big} end)
  end
end
