defmodule MoldDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :mold_demo,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:norm, "~> 0.13"},
      {:mold, github: "dyackson/mold"}
    ]
  end
end
