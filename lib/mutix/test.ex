defmodule Mutix.Test do
  @moduledoc false

  def compile_and_run(ast, meta) do
    Code.compile_quoted(ast)

    # ExUnit.run([MutixTest])
    ExUnit.run()
  end
end
