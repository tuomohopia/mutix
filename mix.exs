defmodule Mutix.MixProject do
  use Mix.Project

  def project do
    [
      app: :mutix,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [
        mutate: :test,
        custom_test: :test
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mimic, "~> 1.7"},
      {:mock, "~> 0.3.0"},
      {:meck, "~> 0.9.2"}
    ]
  end
end
