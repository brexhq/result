defmodule HelpersTest do
  @moduledoc false
  use ExUnit.Case

  import ExResult.Helpers

  doctest ExResult.Helpers

  test "normalize_error" do
    assert {:error, :test} = normalize_error(:error, :test)

    assert {:error, :normalized} = normalize_error(:error)

    assert {:error, :not_found} = normalize_error({:error, :not_found}, :test)

    assert {:ok, 2} = normalize_error({:ok, 2})

    assert :ok = normalize_error(:ok)
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
end
