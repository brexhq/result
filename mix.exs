defmodule Brex.Result.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :brex_result,
      version: "0.4.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      # For ex_docs
      name: "Brex.Result",
      source_url: "https://github.com/brexhq/result",
      docs: [
        logo: "./bind.png",
        main: "readme",
        extras: ["README.md", "CONTRIBUTING.md", "CHANGELOG.md", "RELEASING.md"]
      ],
      # For excoveralls
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Tools to handle three common return values in Elixir: `:ok | {:ok, value} | {:error, reason}`
    """
  end

  defp package do
    [
      maintainers: ["Lizzie Paquette"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/brexhq/result/"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:test, :dev], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.20", only: :dev, runtime: false}
    ]
  end
end
