defmodule Mutix.TransformTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Mutix.Transform

  @single_source_file "test/support/single_operator_source.ex"
  @multi_source_file "test/support/multi_operator_source.ex"

  describe "mutation_modules/2" do
    @single_operator_transformed """
    defmodule Mutix.SingleOperatorSource do
      def larger_than_1(a) do
        a < 1
      end
    end
    """

    setup do
      [single_ast, multi_ast] =
        [@single_source_file, @multi_source_file]
        |> Enum.map(&File.read!/1)
        |> Enum.map(&Code.string_to_quoted!/1)

      %{single_ast: single_ast, multi_ast: multi_ast}
    end

    test "transforms a single operator module AST into a single order mutation AST", %{
      single_ast: module
    } do
      from = :>
      to = :<

      assert [{meta, mutated_module}] = Transform.mutation_modules(module, {from, to})
      assert meta == [line: 3]

      assert Macro.to_string(mutated_module) ==
               String.trim_trailing(@single_operator_transformed, "\n")
    end
  end
end
