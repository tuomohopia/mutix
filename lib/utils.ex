defmodule Mutix.Utils do
  @moduledoc false

  @doc """
  Takes in a module AST and
  generates a new AST per every mutation.


  2. Generate a list of new ASTs where every AST is the full module with a single mutation
  3.

  TODO:
  # - recorded function as input
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

    IO.inspect(operator_location_metas, label: "metas")
  end

  # OLD

  defp prewalker(module_ast) do
    Macro.prewalk(module_ast, fn node ->
      case node do
        {:+, meta, children} ->
          {:-, meta, children}

        other ->
          other
      end
    end)
  end
end
