defmodule MutixTest do
  use ExUnit.Case, async: false

  test "add_one/1" do
    assert Mutix.add_one(2) == 3
  end

  test "add_two/1" do
    assert Mutix.add_two(5) == 7
  end

  test "add_two_and_three/1" do
    assert Mutix.add_two_and_three(5) == 10
  end
end
