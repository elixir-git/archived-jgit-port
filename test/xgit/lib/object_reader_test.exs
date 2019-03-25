defmodule Xgit.Lib.ObjectReaderTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.ObjectReader
  alias Xgit.Test.MockObjectReader

  describe "abbreviate/3" do
    test "shortcut if requested length is 40" do
      reader = %MockObjectReader{objects: %{}}

      assert ObjectReader.abbreviate(reader, "f2786440430e74a46dad158e7bd6059d02b8bd9a", 40) ==
               "f2786440430e74a46dad158e7bd6059d02b8bd9a"
    end

    test "defaults to 7-digit abbreviation" do
      reader = %MockObjectReader{objects: %{}}

      assert ObjectReader.abbreviate(reader, "f2786440430e74a46dad158e7bd6059d02b8bd9a") ==
               "f278644"
    end

    test "accepts proposed abbreviation if no objects" do
      reader = %MockObjectReader{objects: %{}}

      assert ObjectReader.abbreviate(reader, "f2786440430e74a46dad158e7bd6059d02b8bd9a", 7) ==
               "f278644"
    end

    test "extends abbreviation if necessary to make it unique" do
      reader = %MockObjectReader{
        objects: %{
          "f2786440430e74a46dad158e7bd6059d02b8bd9a" => true,
          "f2786440440e74a46dad158e7bd6059d02b8bd9a" => true
        }
      }

      assert ObjectReader.abbreviate(reader, "f2786440430e74a46dad158e7bd6059d02b8bd9a", 7) ==
               "f278644043"
    end
  end
end
