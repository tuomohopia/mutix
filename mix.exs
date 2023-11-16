defmodule Mutix.MixProject do
  use Mix.Project

  def project do
    [
      app: :mutix,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: false,
      deps: deps()
    ]
  end

  def application do
    []
  end

  def cli do
    [
      preferred_envs: [
        mutate: :test
      ]
    ]
  end

  defp deps do
    []
  end
end
