defmodule Mutix do
  alias Mutix.Report
  alias Mutix.Transform

  defdelegate mutation_report(test_results, source_file, mutation), to: Report, as: :mutation
  defdelegate mutation_modules(ast, mutation), to: Transform
end
