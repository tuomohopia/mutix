defmodule Mix.Tasks.Mutate do
  @moduledoc """
  Run with `MIX_ENV=test mix mutate lib/filename.ex test/filename.exs`
  """

  alias Mutix.Utils

  @shortdoc "Runs mutation tests for a given file and test suite."

  @compile {:no_warn_undefined, [ExUnit, ExUnit.Filters]}

  # @env_error_message "You need to run this command with MIX_ENV=test in order to run the test suite."

  use Mix.Task

  @test_module """
  defmodule Mutix do
    def add_one(a) do
      a - 1
    end
  end
  """

  @impl Mix.Task
  # def run([source_file, test_file]) do
  def run(_args) do
    source_file = "lib/mutix.ex"
    test_file = "test/mutix_test.exs"
    # Initial checks

    unless System.get_env("MIX_ENV") || Mix.env() == :test do
      Mix.raise("""
      "mix mutate" is running in the \"#{Mix.env()}\" environment. If you are \
      running mutation tests from within another command, you can either:

        1. set MIX_ENV explicitly:

            MIX_ENV=test mix mutate

        2. set the :preferred_envs for "def cli" in your mix.exs:

            def cli do
              [preferred_envs: ["mutate": :test]]
            end
      """)
    end

    unless File.exists?(source_file), do: Mix.raise("Source module file must exist")
    unless File.exists?(test_file), do: Mix.raise("Test file must exist")
    _ = Mix.Project.get!()

    # Load ExUnit before we compile anything in case we are compiling
    # helper modules that depend on ExUnit.
    Application.ensure_loaded(:ex_unit)

    Code.put_compiler_option(:ignore_module_conflict, true)
    # Code.require_file(Path.join("test", "test_helper.exs"))
    Mix.Task.run("compile", [])

    # Mix.Task.run("app.start", [])
    # ExUnit.start(autorun: false)
    # ExUnit.Server.modules_loaded(false)
    # Code.required_files()
    Code.unrequire_files([source_file])

    # ExUnit.run([MutixTest])

    IO.inspect(Mutix.add_one(5), label: "MutixOnlyForMix.add_one/1 before")
    do_run(source_file)
    IO.inspect(Mutix.add_one(5), label: "MutixOnlyForMix.add_one/1 after")
    :ok
  end

  # Internal

  defp do_run(source_file) do
    # Get source file's AST
    ast = source_file |> File.read!() |> Code.string_to_quoted!()

    # ( Analyze: Find all locations where the operator exists -> save location for quick lookups)

    # Generate a list of new ASTs where every AST is the full module with a single mutation

    mutated_module_asts = Utils.mutation_modules(ast)
    # Run tests against the AST -> report results

    # PER MUTATION: Transform AST with a single order mutation
    # - Find first un-tested (un-mutated) node and mutate it
    # - run
  end

  defp ad_hoc_module do
    # Code.compile_string(@test_module) |> IO.inspect(label: "inline compiled module")
    # Code.eval_string(@test_module) |> IO.inspect(label: "evaluated")

    # IO.inspect(Mutix.add_one(5), label: "MutixOnlyForMix.add_one/1 before")
    quoted = Code.string_to_quoted!(@test_module)
    # IO.inspect(quoted, label: "quoted")
    Code.compile_quoted(quoted)
    Code.ensure_compiled!(Mutix)
    # IO.inspect(Mutix.add_one(5), label: "MutixOnlyForMix.add_one/1 after")
  end
end
