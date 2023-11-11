defmodule Mutix.Transform do
  @moduledoc false

  @doc """
  Takes in a module AST and
  generates a new AST per every mutation.

  Returns a tuple with metadata (line number) on the left
  and transformed module AST on the right.
  """
  @spec mutation_modules(Macro.t(), {atom(), atom()}) :: list({Keyword.t(), Macro.t()})
  def mutation_modules(module_ast, {from, to}) do
    # Find all locations [[line: 3], ..] where `from` exists
    # TODO: multi operator per line support with Macro.update_meta(..)
    # -> put keyword here from acc, like `index_on_line: 0`
    {_new_ast, operator_location_metas} =
      Macro.prewalk(module_ast, [], fn
        {^from, meta, children}, acc ->
          {{from, meta, children}, acc ++ [meta]}

        other, acc ->
          {other, acc}
      end)

    # Generate a list of new ASTs where every AST is the full module with a single mutation

    # TODO: support for multiple identical operators per line
    # - pass index to mutate_at_location
    # - reduce with prewalk/3 and keep tabs with the acc if mutated yet or not
    for meta <- Enum.uniq(operator_location_metas) do
      mutated_module = mutate_at_location(module_ast, meta, {from, to})
      {meta, mutated_module}
    end
  end

  # Internal

  defp mutate_at_location(module_ast, meta, {from, to}) do
    Macro.prewalk(module_ast, fn node ->
      case node do
        {^from, ^meta, children} ->
          {to, meta, children}

        other ->
          other
      end
    end)
  end
end
