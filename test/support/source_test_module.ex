defmodule Mutix.SourceTestModule do
  def add_one(a) do
    a + 1
  end

  def add_two(a) do
    a + 2
  end

  def add_two_and_three(a) do
    a + 2 + 3
  end

  def non_tested_add(a) do
    a + 25
  end

  def non_tested_add_2(a) do
    a + 25
  end
end
