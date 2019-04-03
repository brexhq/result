defmodule ResultTest do
  @moduledoc false
  use ExUnit.Case
  import Result

  doctest Result

  # TODO: test side effects
  def sgn(x) do
    if x > 0 do
      {:ok, "pos"}
    else
      {:error, "neg"}
    end
  end

  def two_args(x, y), do: {:ok, x - y}

  def inside_bind(x, f), do: x ~>> f.()

  test "bind" do
    assert_raise FunctionClauseError, fn ->
      bind(:ok, &sgn/1)
    end

    assert {:ok, "pos"} = bind({:ok, 1}, &sgn/1)

    assert {:error, "neg"} = bind({:ok, -4}, &sgn/1)

    assert {:error, -4} = bind({:error, -4}, &sgn/1)

    assert {:ok, :bar} = bind({:ok, :foo}, fn _ -> {:ok, :bar} end)

    assert {:error, :foo} = bind({:error, :foo}, fn _ -> {:ok, :bar} end)

    assert_raise ArgumentError, fn ->
      bind({:ok, 2}, fn _ -> :ok end)
    end

    assert_raise ArgumentError, fn ->
      bind({:ok, 2}, & &1)
    end
  end

  test "~>>" do
    assert_raise FunctionClauseError, fn ->
      :ok ~>> sgn
    end

    assert {:ok, "pos"} = {:ok, 1} ~>> sgn

    assert {:error, "neg"} = {:ok, -3} ~>> sgn

    assert {:error, 2} = {:error, 2} ~>> sgn

    assert {:ok, 1} = {:ok, 3} ~>> two_args(2)

    assert {:ok, 1} = {:ok, 3} ~>> two_args(2)

    assert {:ok, 1} = {:ok, 3} ~>> two_args(2)

    assert {:error, 1} = {:ok, 1} |> inside_bind(fn x -> {:error, x} end)

    assert {:ok, 2} = {:ok, 1} |> inside_bind(fn x -> {:ok, x + 1} end)

    assert {:error, 1} = {:error, 1} |> inside_bind(&{:ok, &1})

    assert_raise ArgumentError, fn ->
      {:ok, 1} ~>> (fn _x -> raise(ArgumentError) end).()
    end

    assert {:ok, 2} =
             {:ok, 1} ~>> (fn x -> if x > 1, do: raise(ArgumentError), else: {:ok, 2} end).()
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

  test "normalize_error" do
    assert {:error, :test} = normalize_error(:error, :test)

    assert {:error, :normalized} = normalize_error(:error)

    assert {:error, :not_found} = normalize_error({:error, :not_found}, :test)

    assert {:ok, 2} = normalize_error({:ok, 2})

    assert :ok = normalize_error(:ok)
  end

  test "extract!" do
    assert 1 = extract!({:ok, 1})

    assert_raise ArgumentError, fn -> extract!({:error, 1}) end

    assert_raise FunctionClauseError, fn -> extract!(:ok) end
  end

  test "lift" do
    assert {:error, :not_found} =
             nil
             |> lift(nil, :not_found)

    assert {:ok, 2} =
             2
             |> lift(nil, :not_found)

    assert {:error, :not_found} =
             2
             |> lift(fn x -> x == 2 end, :not_found)

    assert {:ok, "test"} =
             "test"
             |> lift(fn x -> x == 2 end, fn x -> x <> "ed" end)

    assert {:error, "tested"} =
             "test"
             |> lift(&(&1 == "test"), fn x -> x <> "ed" end)

    assert {:error, "tested"} =
             "test"
             |> lift("test", &(&1 <> "ed"))
  end

  test "map_error" do
    assert {:error, 3} = map_error({:error, 1}, fn x -> x + 2 end)

    assert {:ok, 1} = map_error({:ok, 1}, fn x -> x + 2 end)

    assert :ok = map_error(:ok, fn x -> x + 2 end)
  end

  test "mask_error" do
    assert {:error, :new_reason} = mask_error({:error, 1}, :new_reason)

    assert {:ok, 1} = mask_error({:ok, 1}, :new_reason)

    assert :ok = mask_error(:ok, :new_reason)

    assert {:error, {:new_reason, "test"}} = mask_error({:error, 1}, {:new_reason, "test"})
  end

  # TODO: capture logs and test other log levels.
  test "log_error error case" do
    # logs generic error
    assert {:error, 1} ==
             log_error({:error, 1}, "")

    # logs error with specific message and metadata
    assert {:error, 1} ==
             log_error({:error, 1}, "test", meta: "test meta")

    # logs error with metadata and generic message
    assert {:error, 1} ==
             log_error({:error, 1}, "", meta: "test meta")

    # logs error with specific message
    assert {:error, 1} ==
             log_error({:error, 1}, "test")
  end

  test "log_error success cases" do
    # should not log.
    assert {:ok, 1} ==
             log_error({:ok, 1}, "test", meta: "test meta")

    assert :ok ==
             log_error(:ok, "")
  end

  test "convert_error" do
    assert {:ok, 1} =
             {:ok, 1}
             |> convert_error(:test)

    assert :ok =
             :ok
             |> convert_error(:test)

    assert {:error, 1} =
             {:error, 1}
             |> convert_error(:test)

    assert :ok =
             {:error, :test}
             |> convert_error(:test)

    assert :ok =
             {:error, 1}
             |> convert_error(&(&1 == 1))
  end

  test "convert_error with value" do
    assert {:ok, 2} =
             {:error, :test}
             |> convert_error(:test, 2)

    assert {:ok, 2} =
             {:error, 1}
             |> convert_error(&(&1 == 1), 2)

    assert {:error, 3} =
             {:error, 3}
             |> convert_error(:test, 2)

    assert {:ok, 3} =
             {:ok, 3}
             |> convert_error(:test, 2)

    assert :ok =
             :ok
             |> convert_error(:test, 2)

    assert {:error, 3} =
             {:error, 3}
             |> convert_error(&(&1 == 1), 2)

    assert {:ok, 3} =
             {:ok, 3}
             |> convert_error(&(&1 == 1), 2)

    assert :ok =
             :ok
             |> convert_error(&(&1 == 1), 2)

    assert {:ok, :foo} =
             {:ok, :foo}
             |> convert_error(fn _ -> true end, :bar)
  end

  test "convert_error with function" do
    assert {:ok, :bar} =
             {:error, :foo}
             |> convert_error(:foo, fn _ -> {:ok, :bar} end)

    assert {:ok, :foo} =
             {:ok, :foo}
             |> convert_error(:foo, fn _ -> {:ok, :bar} end)

    assert {:error, :nope} =
             {:error, :nope}
             |> convert_error(:foo, fn _ -> {:ok, :bar} end)

    assert {:error, 3} =
             {:error, 1}
             |> convert_error(&(1 == &1), &{:error, 2 + &1})

    assert {:ok, 3} =
             {:error, 1}
             |> convert_error(&(1 == &1), &{:ok, 2 + &1})
  end

  test "convert_error with side effect" do
    # TODO: write side effect tests
  end

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
             |> reduce_while_success("e", &{:ok, &1 <> &2})

    assert {:error, "test"}

    assert {:error, "B!"} =
             ["a", "b", "c", "d"]
             |> reduce_while_success(
               "e",
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
