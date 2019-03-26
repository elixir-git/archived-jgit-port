defmodule Xgit.Lib.ObjectReaderTest do
  use ExUnit.Case, async: true

  alias Xgit.Errors.MissingObjectError
  alias Xgit.Lib.Constants
  alias Xgit.Lib.ObjectReader
  alias Xgit.Lib.SmallObjectLoader
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

  describe "has_object?/2" do
    test "calls through to strategy" do
      reader = %MockObjectReader{
        objects: %{
          "f2786440430e74a46dad158e7bd6059d02b8bd9a" => true
        }
      }

      assert ObjectReader.has_object?(reader, "f2786440430e74a46dad158e7bd6059d02b8bd9a") == true
      refute ObjectReader.has_object?(reader, "42786440430e74a46dad158e7bd6059d02b8bd9a") == true
    end
  end

  describe "open/3" do
    test "calls through to strategy" do
      reader = %MockObjectReader{
        objects: %{
          "f2786440430e74a46dad158e7bd6059d02b8bd9a" => %{type: 4, data: 'foo'}
        }
      }

      assert ObjectReader.open(reader, "f2786440430e74a46dad158e7bd6059d02b8bd9a") ==
               %SmallObjectLoader{data: 'foo', type: 4}
    end

    test "raises MissingObjectError if missing (known type)" do
      reader = %MockObjectReader{objects: %{}}

      assert_raise MissingObjectError,
                   "Missing commit f2786440430e74a46dad158e7bd6059d02b8bd9a",
                   fn ->
                     ObjectReader.open(
                       reader,
                       "f2786440430e74a46dad158e7bd6059d02b8bd9a",
                       Constants.obj_commit()
                     )
                   end
    end

    test "raises MissingObjectError if missing (unknown type)" do
      reader = %MockObjectReader{objects: %{}}

      assert_raise MissingObjectError,
                   "Missing (unknown type) f2786440430e74a46dad158e7bd6059d02b8bd9a",
                   fn ->
                     ObjectReader.open(reader, "f2786440430e74a46dad158e7bd6059d02b8bd9a")
                   end
    end
  end

  describe "object_size/3" do
    test "default implementation works" do
      reader = %MockObjectReader{
        objects: %{
          "f2786440430e74a46dad158e7bd6059d02b8bd9a" => %{type: 4, data: 'foo'}
        }
      }

      assert ObjectReader.object_size(reader, "f2786440430e74a46dad158e7bd6059d02b8bd9a") == 3
    end

    test "will honor non-default implementation" do
      reader = %MockObjectReader{
        skip_default_object_size?: true,
        objects: %{
          "f2786440430e74a46dad158e7bd6059d02b8bd9a" => %{type: 4, data: 'foo'}
        }
      }

      assert ObjectReader.object_size(reader, "f2786440430e74a46dad158e7bd6059d02b8bd9a") == 42
    end
  end
end
