defmodule ParseAndAddTest do
  @moduledoc false

  use ExUnit.Case

  import ParseAndAdd

  test "success" do
    file = "hello.txt"
    path = "./" <> file
    assert File.write(path, "10 1 1.5 2.3 5") == :ok
    assert parse(file) == {:ok, 16}
    assert parseX(file) == {:ok, 16}
    assert :ok = File.rm(path)
  end

  test "parse_error" do
    file = "hello.txt"
    path = "./" <> file
    assert File.write(path, "10 1 1.5 bleh 2.3 5") == :ok
    assert parse(file) == {:error, :parse_error}
    assert parseX(file) == {:error, :parse_error}
    assert :ok = File.rm(path)
  end

  test "file error" do
    file = "hey.txt"
    assert parse(file) == {:error, {:nofile, file}}
    assert parseX(file) == {:error, {:nofile, file}}
  end
end
