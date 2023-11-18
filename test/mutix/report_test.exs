defmodule Mutix.ReportTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Mutix.Report

  describe "mutation/3" do
    test "produces a mutation report for the output of a list of mutation test suites" do
      test_results = [
        {%{total: 5, failures: 0, excluded: 0, skipped: 0}, [index_on_line: 0, line: 3],
         "\e[32m.\e[0m\e[32m.\e[0m\e[32m.\e[0m\e[32m.\e[0m\e[32m.\e[0m\nFinished in 0.00 seconds (0.00s async, 0.00s sync)\n\e[32m5 tests, 0 failures\e[0m\n\nRandomized with seed 940459\n"}
      ]

      source_file_path = "test/support/single_operator_source.ex"
      operator_mutation = {:>, :<}

      result =
        Report.mutation(
          test_results,
          {source_file_path, File.read!(source_file_path)},
          operator_mutation
        )

      expected_result = File.read!("test/support/generated/report_result.txt")
      assert result == expected_result
    end

    test "reports mutation score correctly with context" do
      test_results = [
        {%{total: 5, failures: 0, excluded: 0, skipped: 0}, [index_on_line: 0, line: 3], ""},
        {%{total: 5, failures: 1, excluded: 0, skipped: 0}, [index_on_line: 0, line: 5], ""},
        {%{total: 5, failures: 5, excluded: 0, skipped: 0}, [index_on_line: 0, line: 8], ""}
      ]

      source_file_path = "test/support/single_operator_source.ex"
      operator_mutation = {:>, :<}

      result =
        Report.mutation(
          test_results,
          {source_file_path, File.read!(source_file_path)},
          operator_mutation
        )

      if not IO.ANSI.enabled?() do
        assert result =~ "5 tests were run for each mutant."
        assert result =~ "2 / 3 mutants killed by the test suite."
        assert result =~ "Mutation score: 66.7 %"
      else
        # 5 tests were..
        assert result =~ "\e[34m\e[1m5\e[0m tests were run for each mutant"
        # 2 / 3 mutants killed..
        assert result =~ "\e[32m2\e[0m / \e[34m\e[1m3\e[0m mutants killed by the test suite."
        # 66.7 %
        assert result =~ "Mutation score: \e[32m\e[1m66.7\e[0m %"
        # Has context
        assert result =~ "def larger_than_1(a) do"
      end
    end
  end
end
