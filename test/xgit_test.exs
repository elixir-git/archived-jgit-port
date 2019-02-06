defmodule XgitTest do
  use ExUnit.Case
  doctest Xgit

  test "greets the world" do
    assert Xgit.hello() == :world
  end
end
