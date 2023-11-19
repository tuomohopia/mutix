# Mutix

> Mutation testing tool for Elixir

Mutix is a mutation testing tool that generates mutations of your source files
and runs the existing test suite against them.

Generates a mutation report along with a mutation score as the result.

![Mutix result](/assets/screenshot.png?raw=true "Mutix")

## Installation

Add `:mutix` to your test dependencies in your `mix.exs` file:

```elixir
def deps do
  [
    {:mutix, git: "https://github.com/tuomohopia/mutix.git", tag: "v0.1.0", only: [:dev, :test]}
  ]
end
```

Then add `:test` as the preferred `MIX_ENV` for the mix task of `mutix` in your
`mix.exs` file:

```elixir
def project do
  preferred_cli_env: [
    mutate: :test
  ]
```

Or optionally

```elixir
def cli do
    [preferred_envs: [mutate: :test]]
end
```

## Usage

The mix task takes a source file to mutate as the required parameter.

```bash
mix mutate lib/parser.ex
```

Run `mix help mutate` to see instructions on how to use the tool.

### Command line options

- `--from` - which target operator to mutate
- `--to` - which operator should the target operator be mutated to in the source
  file

If `--from` and `--to` are not defined, `--from` defaults to `+` and `--to` to
`-`.

### Examples

```bash
mix mutate lib/parser.ex --from ">" --to "<"
```

```bash
mix mutate lib/parser.ex --from and --to not
```

## Caveats

The current version comes with the following caveats:

- **Macros**: Mutates operators even inside macros. This can lead to very
  confusing results
- **Single source**: Only mutates a single source file at a time. This is
  because producing mutations and running the test suite on each one of them is
  computationally expensive and this is not optimized yet
