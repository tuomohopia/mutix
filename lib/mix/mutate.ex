defmodule Mix.Tasks.Mutate do
  @moduledoc """
  Run with `MIX_ENV=test mix mutate lib/filename.ex test/filename.exs`
  """

  alias Mutix.Report
  alias Mutix.Transform

  @mutation_operators %{
    "plus_to_minus" => {:+, :-},
    "minus_to_plus" => {:-, :+}
  }

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
    # Initial checks

    unless System.get_env("MIX_ENV") || Mix.env() == :test do
      Mix.raise(@mix_env_error)
    end

    if Mix.Task.recursing?(), do: Mix.raise("Umbrella apps not supported yet.")
    unless File.exists?(source_file), do: Mix.raise("Source module file must exist.")
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

    # Finally parse, require and load the files
    test_elixirc_options = project[:test_elixirc_options] || []
    test_pattern = project[:test_pattern] || "*_test.exs"
    warn_test_pattern = project[:warn_test_pattern] || "*_test.ex"

    matched_test_files =
      []
      |> parse_files(shell, test_paths)
      |> Mix.Utils.extract_files(test_pattern)

    if Enum.empty?(matched_test_files), do: Mix.raise("No ExUnit test files found.")

    do_run(source_file, matched_test_files)
    # |> Enum.map(fn {result, _meta, _input} -> result end)
    |> IO.inspect()
  end

  def run(_),
    do:
      Mix.raise(
        "Please provide path to the source file to mutate, e.g. `mix mutate lib/my_app/transformer.ex`. Other options unsupported at this time."
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

    # TODO: put operator to its own map/config, allow configuring via cmd line opts
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

    # REPORT:
    # - Which mutation operator was used?
    # - How many mutations were generated?
    # - How many tests were run against each mutant?
    # - Mutation Score
    #   - How many mutants caught
    #   - How many mutants survived
    #   - Score

    # exunit_report = Report.detailed_results(test_results)
    mutation_report = Report.mutation(test_results, source_file, {:+, :-})
    IO.puts(mutation_report)
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

  defp parse_files([], _shell, test_paths) do
    test_paths
  end

  defp parse_files([single_file], _shell, _test_paths) do
    # Check if the single file path matches test/path/to_test.exs:123. If it does,
    # apply "--only line:123" and trim the trailing :123 part.
    {single_file, opts} = ExUnit.Filters.parse_path(single_file)
    ExUnit.configure(opts)
    [single_file]
  end

  defp parse_files(files, shell, _test_paths) do
    if Enum.any?(files, &match?({_, [_ | _]}, ExUnit.Filters.parse_path(&1))) do
      raise_with_shell(shell, "Line numbers can only be used when running a single test file")
    else
      files
    end
  end

  defp filter_to_allowed_files(matched_test_files, nil), do: matched_test_files

  defp filter_to_allowed_files(matched_test_files, %MapSet{} = allowed_files) do
    Enum.filter(matched_test_files, &MapSet.member?(allowed_files, Path.expand(&1)))
  end
end
