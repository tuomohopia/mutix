defmodule Mix.Tasks.Mutate do
  @moduledoc """
  Run with `mix mutate lib/filename.ex test/filename.exs`
  """

  @shortdoc "Runs mutation tests for a given file and test suite."

  use Mix.Task

  @impl Mix.Task
  def run([source_file, test_file] = args) do
    Mix.shell().info(Enum.join(args, " "))
  end
end
