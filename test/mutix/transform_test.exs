defmodule Mutix.TransformTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Mutix.Transform

  @source_file "test/support/single_operator_source.ex"

  describe "mutation_modules/2" do
    @single_operator_transformed """
    defmodule Mutix.SingleOperatorSource do
      def larger_than_1(a) do
        a < 1
      end
    end
    """
    setup do
      ast = @source_file |> File.read!() |> Code.string_to_quoted!()
      %{module: ast}
    end

    test "transforms a single module AST into a list of single order mutation ASTs", %{
      module: module
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
