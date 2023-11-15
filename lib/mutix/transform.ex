defmodule Mutix.Transform do
  @moduledoc """
  Transforms a source module AST into mutated ASTs,
  along with relevant metadata for mutation reporting.
  """

  @doc """
  Takes in a module AST and
  generates a new AST per every mutation.

  Returns a tuple with metadata (line number) on the left
  and transformed module AST on the right.
  """
  @spec mutation_modules(Macro.t(), {atom(), atom()}) :: list({Keyword.t(), Macro.t()})
  def mutation_modules(module_ast, {from, to}) do
    # Find all locations [[line: 3, index_on_line: 0], ..] where `from` exists
    {new_ast, operator_location_metas} =
      Macro.prewalk(module_ast, [], fn
        {^from, meta, children}, acc ->
          index_on_line = index_for_line(acc, meta)
          meta = Keyword.put(meta, :index_on_line, index_on_line)
          {{from, meta, children}, acc ++ [meta]}

        other, acc ->
          {other, acc}
      end)

    # Generate a list of new ASTs where every AST is the full module with a single mutation
    for meta <- Enum.uniq(operator_location_metas) do
      mutated_module = mutate_at_location(new_ast, meta, {from, to})
      {meta, mutated_module}
    end
  end

  # Internal

  defp mutate_at_location(module_ast, meta, {from, to}) do
    Macro.prewalk(module_ast, fn
      {^from, ^meta, children} ->
        {to, meta, children}

      other ->
        other
    end)
  end

  defp index_for_line(acc, current_node_meta) do
    current_line = Keyword.fetch!(current_node_meta, :line)

    acc
    |> Enum.filter(&(Keyword.fetch!(&1, :line) == current_line))
    |> Enum.count()
  end
end
