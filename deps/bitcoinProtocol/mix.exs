defmodule Project4.MixProject do
  use Mix.Project

  def project do
    [
      app: :bitcoinProtocol, 
      version: "0.8.0",
      description: "A simple implementation of bitcoin protocol",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      escript: escript(),
      package: package(),
      deps: deps()
    ]
  end

  def escript do
    [main_module: Main]
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
      {:rsa_ex, "~> 0.4"},
      {:poison, "~> 3.1"},
      {:ex_doc, "~> 0.14", only: :dev}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: ,"https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp package() do
    [
      name: "bitcoinProtocol",
      licenses: ["MIT License"],
      links: %{"GitHub" => "https://github.com/sriharshamodali/Bitcoin-Protocol"}
    ]
  end
end
