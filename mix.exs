defmodule Result.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :result,
      version: "0.1.3",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Result",
      source_url: "https://github.com/veyond-card/result",
      docs: [extras: ["CONTRIBUTING.md", "CHANGELOG.md", "README.md", "RELEASING.md"]]
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
