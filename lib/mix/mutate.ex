defmodule Mix.Tasks.Mutate do
  @moduledoc ~S"""
  Run with `mix mutate lib/parser.ex` where the first argument
  is the source file to mutate.

  This generates a so called single-order mutation for every `--from` operator
  found in the source code file. In essence, a version of the app is created
  for every operator to be mutated is found, and the test suite is run against it.

  To configure which operator to mutate to which, use
  `--from` and `--to` command line arguments:

      $ mix mutate lib/parser.ex --from + --to -
      $ mix mutate lib/parser.ex --from and --to not
      $ mix mutate lib/parser.ex --from ">" --to "<"

  """

  @shortdoc "Runs mutation tests for a given file and test suite."

  @compile {:no_warn_undefined, [ExUnit, ExUnit.Filters]}

  @operators %{
    "+" => :+,
    "-" => :-,
    "*" => :*,
    "/" => :/,
    "and" => :and,
    "not" => :not,
    "&&" => :&&,
    "||" => :||,
    ">" => :>,
    ">=" => :>=,
    "<" => :<,
    "<=" => :<=,
    "==" => :==,
    "!=" => :!=
  }

  @switches [
    from: :string,
    to: :string
  ]

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
  def run(args) do
    {opts, source_files} = OptionParser.parse!(args, strict: @switches)

    from = Keyword.get(opts, :from, "+")
    to = Keyword.get(opts, :to, "-")

    operators = Map.keys(@operators)

    unless from in operators and to in operators,
      do:
        Mix.raise(
          "Both from and to mutation operators have to be among the allowed operators: #{Enum.join(operators, ", ")}."
        )

    operators = {Map.fetch!(@operators, from), Map.fetch!(@operators, to)}

    # Initial checks

    source_file_count = Enum.count(source_files)

    if source_file_count == 0,
      do:
        Mix.raise(
          "Please provide path to the source file to mutate, e.g. `mix mutate lib/my_app/transformer.ex`."
        )

    if source_file_count > 1,
      do: Mix.raise("Only one source file supported at this time.")

    source_file = List.first(source_files)

    unless System.get_env("MIX_ENV") || Mix.env() == :test do
      Mix.raise(@mix_env_error)
    end

    if Mix.Task.recursing?(), do: Mix.raise("Umbrella apps not supported yet.")

    unless File.exists?(source_file),
      do: Mix.raise("Source module file #{source_file} does not exist.")

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
    test_pattern = project[:test_pattern] || "*_test.exs"

    matched_test_files =
      []
      |> parse_files(shell, test_paths)
      |> Mix.Utils.extract_files(test_pattern)

    if Enum.empty?(matched_test_files), do: Mix.raise("No ExUnit test files found.")

    do_run(source_file, matched_test_files, operators)
  end

  # Internal

  defp do_run(source_path, test_files, mutation) do
    # Get source file's AST
    source_content = File.read!(source_path)
    ast = Code.string_to_quoted!(source_content)
    {:ok, test_modules, _compilation_metas} = Kernel.ParallelCompiler.require(test_files, [])

    ExUnit.Server.modules_loaded(false)
    # One clean run first to assert all tests pass
    ExUnit.CaptureIO.with_io(fn ->
      case ExUnit.run() do
        %{failures: 0, total: total, excluded: excluded, skipped: skipped}
        when excluded + skipped == total ->
          Mix.raise("No tests to run detected. Exited without running a mutation test suite.")

        %{failures: 0} ->
          :ok

        %{failures: failures} ->
          Mix.raise(
            "Test suite has #{failures} failures without mutations. All tests need to pass before mutation suite can be run."
          )
      end
    end)

    test_results =
      for {meta, ast} <- Mutix.mutation_modules(ast, mutation) do
        Code.compile_quoted(ast)

        {result, io_output} =
          ExUnit.CaptureIO.with_io(fn ->
            ExUnit.run(test_modules)
          end)

        Code.unrequire_files(test_files)
        {result, meta, io_output}
      end

    mutation_report =
      if Enum.empty?(test_results) do
        {from, _to} = mutation

        """

        No ( #{from} ) operators found in #{source_path}.
        Thus, no mutants injected.

        """
      else
        Mutix.mutation_report(test_results, {source_path, source_content}, mutation)
      end

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
end
