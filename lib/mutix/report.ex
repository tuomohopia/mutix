defmodule Mutix.Report do
  @moduledoc false

  @typep mutation_test_result :: {result :: map(), meta :: Keyword.t(), io_output :: String.t()}

  @doc """
  Lists detailed results of each test:
  - what was mutated and on which line
    - "Second + operator on line 7 was mutated to -."
  - Exunit's colorized assertion.
  """
  @spec detailed_results(list(mutation_test_result())) :: nil
  def detailed_results(test_results) do
  end

  @spec mutation(list(mutation_test_result()), String.t(), {atom(), atom()}) :: nil
  def mutation(test_results, source_file_path, operator_mutation) do
    score = mutation_score(test_results)
    percentage = score.survived_count / score.mutant_count * 100
    survived = score.survived

    survived_report =
      if Enum.count(survived) > 0,
        do: survived_report(survived, source_file_path, operator_mutation),
        else: nil

    """
    Results:

        #{score.mutant_count} mutants were generated.

        #{score.test_count} tests were run for each mutant.

        #{score.killed_count} mutants killed by the test suite.

        Mutation score: #{percentage} %
    #{survived_report}
    """
  end

  # Internal

  defp mutation_score(test_results) do
    survived = Enum.filter(test_results, fn {%{failures: failures}, _, _} -> failures == 0 end)
    exunit_results = Enum.map(test_results, fn {result, _, _} -> result end)

    mutant_count = Enum.count(exunit_results)
    survived_count = Enum.count(survived)
    killed = mutant_count - survived_count

    total = exunit_results |> List.first() |> Map.fetch!(:total)

    %{
      mutant_count: mutant_count,
      killed_count: killed,
      survived_count: survived_count,
      survived: survived,
      test_count: total
    }
  end

  defp survived_report(survived, source_file_path, {from, to}) do
    surviving =
      for {_, meta, _} <- survived do
        line = Keyword.fetch!(meta, :line)
        "#{source_file_path} - line #{line} where ( #{from} ) was mutated into ( #{to} )"
      end

    """


    Surviving mutants (no test failed with these injections):

        #{Enum.join(surviving, "\n    ")}
    """
  end
end
