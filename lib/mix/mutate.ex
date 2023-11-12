defmodule Mix.Tasks.Mutate do
  @moduledoc """
  Run with `MIX_ENV=test mix mutate lib/filename.ex test/filename.exs`
  """

  alias Mutix.Test
  alias Mutix.Transform

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

  use Mix.Task

  @impl Mix.Task
  def run([source_file]) do
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
    ExUnit.start(autorun: false)
    Mix.Task.run("compile", [])
    # Mix.Task.run("app.start", [])
    Code.unrequire_files([source_file])

    shell = Mix.shell()
    test_paths = project[:test_paths] || default_test_paths()
    Enum.each(test_paths, &require_test_helper(shell, &1))

    # TODO:
    # - get test files properly
    do_run(source_file, [test_file])
    :ok
  end

  def run(_),
    do:
      Mix.raise(
        "Please provide path to the source file to mutate, e.g. `mix mutate lib/my_app/transformer.ex`"
      )

  # Internal

  defp do_run(source_file, test_files) do
    # Get source file's AST
    ast = source_file |> File.read!() |> Code.string_to_quoted!()
    {:ok, test_modules, []} = Kernel.ParallelCompiler.require(test_files, [])

    ExUnit.Server.modules_loaded(false)
    # One clean run first to assert all tests pass
    ExUnit.CaptureIO.with_io(fn ->
      case CustomExUnit.run() do
        %{failures: 0} ->
          :ok

        %{failures: failures} ->
          Mix.raise(
            "Test suite has #{failures} failures without mutations. All tests need to pass before mutation suite can be run."
          )
      end
    end)

    test_results =
      for {meta, ast} <- Transform.mutation_modules(ast, {:+, :-}) do
        Code.compile_quoted(ast)

        {result, io_output} =
          ExUnit.CaptureIO.with_io(fn ->
            CustomExUnit.run(test_modules)
          end)

        Code.unrequire_files(test_files)
        {result, meta, io_output}
      end

    mutation_score = Test.mutation_score(test_results)
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
end
