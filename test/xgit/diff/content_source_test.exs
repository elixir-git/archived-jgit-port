defmodule Xgit.Diff.ContentSourceTest do
  use ExUnit.Case, async: true

  alias Xgit.Diff.ContentSource
  alias Xgit.Lib.SmallObjectLoader
  alias Xgit.Test.MockObjectReader

  doctest Xgit.Diff.ContentSource

  test "size/3" do
    reader = %MockObjectReader{
      objects: %{
        "f2786440430e74a46dad158e7bd6059d02b8bd9a" => %{type: 4, data: 'foo'}
      }
    }

    assert ContentSource.size(
             reader,
             "some/random/path",
             "f2786440430e74a46dad158e7bd6059d02b8bd9a"
           ) == 3
  end

  test "open/3" do
    reader = %MockObjectReader{
      objects: %{
        "f2786440430e74a46dad158e7bd6059d02b8bd9a" => %{type: 4, data: 'foo'}
      }
    }

    assert ContentSource.open(
             reader,
             "some/random/path",
             "f2786440430e74a46dad158e7bd6059d02b8bd9a"
           ) ==
             %SmallObjectLoader{data: 'foo', type: 4}
  end
end
