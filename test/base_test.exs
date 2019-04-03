defmodule BaseTest do
  @moduledoc false
  use ExUnit.Case

  import Result.Base

  doctest Result.Base

  def sgn(x) do
    if x > 0 do
      {:ok, "pos"}
    else
      {:error, "neg"}
    end
  end

  def two_args(x, y), do: {:ok, x - y}

  def inside_bind(x, f), do: x ~> f.()

  test "bind" do
    assert_raise FunctionClauseError, fn ->
      bind(:ok, &sgn/1)
    end

    assert {:ok, "pos"} = bind({:ok, 1}, &sgn/1)

    assert {:error, "neg"} = bind({:ok, -4}, &sgn/1)

    assert {:error, -4} = bind({:error, -4}, &sgn/1)

    assert {:ok, :bar} = bind({:ok, :foo}, fn _ -> {:ok, :bar} end)

    assert {:error, :foo} = bind({:error, :foo}, fn _ -> {:ok, :bar} end)

    assert_raise CaseClauseError, fn ->
      bind({:ok, 2}, fn _ -> :ok end)
    end

    assert_raise CaseClauseError, fn ->
      bind({:ok, 2}, & &1)
    end
  end

  test "~>" do
    assert_raise FunctionClauseError, fn ->
      :ok ~> sgn
    end

    assert {:ok, "pos"} = {:ok, 1} ~> sgn

    assert {:error, "neg"} = {:ok, -3} ~> sgn

    assert {:error, 2} = {:error, 2} ~> sgn

    assert {:ok, 1} = {:ok, 3} ~> two_args(2)

    assert {:ok, 1} = {:ok, 3} ~> two_args(2)

    assert {:ok, 1} = {:ok, 3} ~> two_args(2)

    assert {:error, 1} = {:ok, 1} |> inside_bind(fn x -> {:error, x} end)

    assert {:ok, 2} = {:ok, 1} |> inside_bind(fn x -> {:ok, x + 1} end)

    assert {:error, 1} = {:error, 1} |> inside_bind(&{:ok, &1})

    assert {:ok, [3, 4, 5]} = {:ok, [1, 2, 3]} ~> Result.Mappers.map_while_success(&{:ok, &1 + 2})

    assert_raise ArgumentError, fn ->
      {:ok, 1} ~> (fn _ -> raise ArgumentError end).()
    end

    assert {:ok, 2} =
             {:ok, 1} ~> (fn x -> if x > 1, do: raise(ArgumentError), else: {:ok, 2} end).()
  end

  test "fmap" do
    assert_raise FunctionClauseError, fn ->
      :ok
      |> fmap(fn x -> x + 2 end)
    end

    assert {:ok, 8} =
             {:ok, 6}
             |> fmap(fn x -> x + 2 end)

    assert {:error, 6} =
             {:error, 6}
             |> fmap(fn x -> x + 2 end)
  end

  test "ignore" do
    assert :ok = ignore({:ok, 2})

    assert :ok = ignore(:ok)

    assert {:error, :not_found} = ignore({:error, :not_found})
  end

  test "extract!" do
    assert 1 = extract!({:ok, 1})

    assert_raise ArgumentError, fn -> extract!({:error, 1}) end

    assert_raise FunctionClauseError, fn -> extract!(:ok) end
  end
end
