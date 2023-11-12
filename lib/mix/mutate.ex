defmodule Mix.Tasks.Mutate do
  @moduledoc """
  Run with `MIX_ENV=test mix mutate lib/filename.ex test/filename.exs`
  """

  alias Mutix.Test
  alias Mutix.Transform
  alias Mix.Compilers.Test, as: CT

  @shortdoc "Runs mutation tests for a given file and test suite."

  @compile {:no_warn_undefined, [ExUnit, ExUnit.Filters]}

  @mix_env_error """
  "mix mutate" is running in the \"#{Mix.env()}\" environment. If you are \
  running mutation tests from within another command, you can either:

    1. set MIX_ENV explicitly:

        MIX_ENV=test mix mutate

    2. set the :preferred_envs for "def cli" in your mix.exs:

        def cli do
          [preferred_envs: ["mutate": :test]]
        end
  """

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
      Mix.raise(@mix_env_error)
    end

    unless File.exists?(source_file), do: Mix.raise("Source module file must exist")
    unless File.exists?(test_file), do: Mix.raise("Test file must exist")
    _ = Mix.Project.get!()
    project = Mix.Project.config()

    # Load ExUnit before we compile anything in case we are compiling
    # helper modules that depend on ExUnit.
    Application.ensure_loaded(:ex_unit)
    Code.put_compiler_option(:ignore_module_conflict, true)
    # Kernel.ParallelCompiler.require(["test/mutix_test.exs", "test/test_helper.exs"], [])
    ExUnit.start(autorun: false)
    # Kernel.ParallelCompiler.require(["test/mutix_test.exs"], [])
    Mix.Task.run("compile", [])
    # Mix.Task.run("app.start", [])
    # ExUnit.Server.modules_loaded(false)
    Code.unrequire_files([source_file])

    ExUnit.after_suite(fn result ->
      nil
    end)

    # ExUnit.configure(ExUnit.configuration())

    shell = Mix.shell()
    test_paths = project[:test_paths] || default_test_paths()
    Enum.each(test_paths, &require_test_helper(shell, &1))

    # IO.inspect(Mutix.add_one(5), label: "MutixOnlyForMix.add_one/1 before")
    do_run(source_file, test_file)
    # IO.inspect(Mutix.add_one(5), label: "MutixOnlyForMix.add_one/1 after")
    :ok
  end

  # Internal

  defp do_run(source_file, test_file) do
    # Get source file's AST
    ast = source_file |> File.read!() |> Code.string_to_quoted!()

    test_results =
      for {meta, ast} <- Transform.mutation_modules(ast, {:+, :-}) do
        task = ExUnit.async_run()

        Kernel.ParallelCompiler.require(["test/mutix_test.exs"], [])
        |> IO.inspect(label: "parallelcompiler")

        ExUnit.Server.modules_loaded(false)
        Code.compile_quoted(ast)

        {result, io_output} =
          ExUnit.CaptureIO.with_io(fn ->
            CustomExUnit.run([MutixTest])
            # ExUnit.await_run(task)
          end)

        Code.unrequire_files([test_file])
        result
      end

    IO.inspect(test_results, label: "test_results")

    # Compile each transformed module & run tests against it
    # Report number of failures to reporter or back here

    # Once last AST tested, aggregate results
  end

  defp require_test_helper(shell, dir) do
    file = Path.join(dir, "test_helper.exs")

    if File.exists?(file) do
      Code.require_file(file)
    else
      raise_with_shell(
        shell,
        "Cannot run tests because test helper file #{inspect(file)} does not exist"
      )
    end
  end

  defp raise_with_shell(shell, message) do
    Mix.shell(shell)
    Mix.raise(message)
  end

  defp default_test_paths do
    if File.dir?("test") do
      ["test"]
    else
      []
    end
  end

  defp ad_hoc_module do
    quoted = Code.string_to_quoted!(@test_module)
    Code.compile_quoted(quoted)
    Code.ensure_compiled!(Mutix)
  end
end
