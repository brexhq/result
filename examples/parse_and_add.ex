defmodule ParseAndAdd do
  @moduledoc """
  Examples using Result
  """
  use Result

  require Logger

  def process_token(token) do
    token
    # {integer(), binary()} | :error
    |> Integer.parse()
    |> case do
      {int, ""} -> {:ok, int}
      # skips it
      {_, _} -> :ok
      :error -> {:error, :parse_error}
    end
  end

  def parseX(file) do
    # {:ok, file} | {:error, :enoent}
    with {:ok, contents} <- File.read(file) do
      contents
      |> String.split()
      |> Enum.reduce_while({:ok, []}, fn token, {:ok, acc} ->
        token
        |> process_token()
        |> case do
          :ok -> {:cont, {:ok, acc}}
          {:ok, int} -> {:cont, {:ok, [int | acc]}}
          err -> {:halt, err}
        end
      end)
      |> case do
        {:ok, result} -> {:ok, Enum.reduce(result, &(&1 + &2))}
        err -> err
      end
    else
      {:error, :enoent} ->
        Logger.error("file: #{file} does not exist")
        {:error, {:nofile, file}}
    end
  end

  def parse(file) do
    file
    |> File.read()
    |> log_error("file: #{file} does not exist")
    |> mask_error({:nofile, file})
    |> fmap(&String.split/1)
    # {:ok, processed enum} | {:error, :parse_error}
    ~> map_while_success(&process_token/1)
    # {:ok, sum} {:error, :parse_error}
    |> fmap(&Enum.reduce(&1, 0, fn x, y -> x + y end))
  end
end
