defmodule Mutix.Transform do
  @moduledoc false

  @doc """
  Takes in a module AST and
  generates a new AST per every mutation.

  TODO:
  # - operator to mutate as an input
  """
  def mutation_modules(module_ast) do
    # 1. ( Analyze: Find all locations where the operator exists -> save location for quick lookups)

    {_new_ast, operator_location_metas} =
      Macro.prewalk(module_ast, [], fn
        {:+, meta, children}, acc ->
          {{:+, meta, children}, acc ++ [meta]}

        other, acc ->
          {other, acc}
      end)

    # Generate a list of new ASTs where every AST is the full module with a single mutation

    # TODO: support for multiple identical operators per line
    # - pass index to mutate_at_location
    # - reduce with prewalk/3 and keep tabs with the acc if mutated yet or not
    for meta <- Enum.uniq(operator_location_metas) do
      mutated_module = mutate_at_location(module_ast, meta)
      {meta, mutated_module}
    end
  end

  # Internal

  defp mutate_at_location(module_ast, meta) do
    Macro.prewalk(module_ast, fn node ->
      case node do
        {:+, ^meta, children} ->
          {:-, meta, children}

        other ->
          other
      end
    end)
  end
end
