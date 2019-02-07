defmodule Xgit.Lib.ConstantsTest do
  use ExUnit.Case

  alias Xgit.Lib.Constants
  doctest Xgit.Lib.Constants

  describe "encode_ascii/1" do
    test "converts integers" do
      assert Constants.encode_ascii(42) == '42'
      assert Constants.encode_ascii(0) == '0'
      assert Constants.encode_ascii(-110) == '-110'
    end

    test "converts a simple ASCII string to charlist" do
      assert Constants.encode_ascii("abc") == 'abc'
    end

    test "raises ArgumentError on non-ASCII input" do
      assert_raise(ArgumentError, fn ->
        Constants.encode_ascii("Ūnĭcōde̽")
      end)
    end
  end
end
