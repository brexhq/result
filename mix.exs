defmodule Brex.Result.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :brex_result,
      version: "0.4.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Brex.Result",
      source_url: "https://github.com/brexhq/result",
      docs: [extras: ["README.md", "CONTRIBUTING.md", "CHANGELOG.md", "RELEASING.md"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.20", only: :dev, runtime: false}
    ]
  end
end
