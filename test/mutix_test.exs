defmodule MutixTest do
  use ExUnit.Case, async: false

  test "add/2" do
    assert Mutix.add_one(2) == 3
  end
end
