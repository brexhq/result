defmodule Brex.Result.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :brex_result,
      version: "0.4.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # For ex_docs
      name: "Brex.Result",
      source_url: "https://github.com/brexhq/result",
      docs: [extras: ["README.md", "CONTRIBUTING.md", "CHANGELOG.md", "RELEASING.md"]],
      # For excoveralls
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
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
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.20", only: :dev, runtime: false}
    ]
  end
end
