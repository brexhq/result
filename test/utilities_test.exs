defmodule UtilitiesTest do
  @moduledoc false
  use ExUnit.Case

  import Utilities

  doctest Utilities

  test "partition" do
    assert %{ok: [4, 1], error: [3, 2], other: [1]} ==
             [{:ok, 1}, {:error, 2}, {:error, 3}, {:ok, 4}, {:other, 1}]
             |> partition
  end

  test "on_match" do
    assert {:bad, 1} = on_match({:bad, 1}, {:good, _}, fn x -> x + 2 end)
    assert 3 = on_match({:good, 1}, {:good, _}, fn {:good, x} -> x + 2 end)
  end

  test "match_pred" do
    assert match_pred({:good, _}).({:good, 1})
    refute match_pred({:good, _}).({:bad, 1})
  end
end
