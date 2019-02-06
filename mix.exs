defmodule Xgit.MixProject do
  use Mix.Project

  def project do
    [
      app: :xgit,
      version: "0.1.0",
      name: "Xgit",
      elixir: "~> 1.8",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      build_per_environment: false,
      test_coverage: [tool: Coverex.Task, coveralls: true],
      description: description(),
      package: package()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:coverex, "~> 1.5", only: :test},
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.19", only: :dev}
    ]
  end

  defp description, do: "Pure Elixir native implementation of git"

  defp package do
    [
      maintainers: ["Eric Scouten"],
      licenses: ["Apache2"],
      links: %{"Github" => "https://github.com/scouten/xgit"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
