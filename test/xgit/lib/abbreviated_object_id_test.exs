defmodule Xgit.Lib.AbbreviatedObjectIdTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.AbbreviatedObjectId
  doctest Xgit.Lib.AbbreviatedObjectId

  test "empty ID is not valid or complete" do
    refute AbbreviatedObjectId.valid?("")
    refute AbbreviatedObjectId.complete?("")
  end

  test "full ID id valid and complete" do
    id = "7b6e8067ec96acef9a4184b43210d583b6d2f99a"

    assert AbbreviatedObjectId.valid?(id)
    assert AbbreviatedObjectId.complete?(id)
  end

  test "one-digit ID is not valid or complete" do
    id = "7"

    refute AbbreviatedObjectId.valid?(id)
    refute AbbreviatedObjectId.complete?(id)
  end

  @valid_ids [
    "7b",
    "7b6",
    "7b6e",
    "7b6e8",
    "7b6e80",
    "7b6e806",
    "7b6e8067",
    "7b6e8067e",
    "7b6e8067ec96acef9"
  ]

  test "short IDs of various lengths are valid but not complete" do
    Enum.each(@valid_ids, fn id ->
      assert AbbreviatedObjectId.valid?(id)
      refute AbbreviatedObjectId.complete?(id)
    end)
  end

  describe "prefix_compare/2" do
    test "full IDs, different at last character" do
      assert AbbreviatedObjectId.prefix_compare(
               "7b6e8067ec96acef9a4184b43210d583b6d2f99a",
               "7b6e8067ec96acef9a4184b43210d583b6d2f99a"
             ) == :eq

      assert AbbreviatedObjectId.prefix_compare(
               "7b6e8067ec96acef9a4184b43210d583b6d2f99a",
               "7b6e8067ec96acef9a4184b43210d583b6d2f99b"
             ) == :lt

      assert AbbreviatedObjectId.prefix_compare(
               "7b6e8067ec96acef9a4184b43210d583b6d2f99a",
               "7b6e8067ec96acef9a4184b43210d583b6d2f999"
             ) == :gt
    end

    test "1-char prefix" do
      assert AbbreviatedObjectId.prefix_compare("7", "7b6e8067ec96acef9a4184b43210d583b6d2f99a") ==
               :eq

      assert AbbreviatedObjectId.prefix_compare("7", "8b6e8067ec96acef9a4184b43210d583b6d2f99a") ==
               :lt

      assert AbbreviatedObjectId.prefix_compare("7", "6b6e8067ec96acef9a4184b43210d583b6d2f99a") ==
               :gt
    end

    test "7-char prefix" do
      assert AbbreviatedObjectId.prefix_compare(
               "7b6e806",
               "7b6e8067ec96acef9a4184b43210d583b6d2f99a"
             ) == :eq

      assert AbbreviatedObjectId.prefix_compare(
               "7b6e806",
               "7b6e8167ec86acef9a4184b43210d583b6d2f99a"
             ) == :lt

      assert AbbreviatedObjectId.prefix_compare(
               "7b6e806",
               "7b6e8057eca6acef9a4184b43210d583b6d2f99a"
             ) == :gt
    end
  end
end
