defmodule Xgit.Lib.ObjectIdTest do
  use ExUnit.Case

  alias Xgit.Lib.ObjectId
  doctest Xgit.Lib.ObjectId

  test "zero/0" do
    zero = ObjectId.zero()
    assert is_binary(zero)
    assert String.length(zero) == 20
    assert ObjectId.valid?(zero)
    assert String.match?(zero, ~r/^0+$/)
  end

  test "valid?/1" do
    assert ObjectId.valid?("1234567890abcdef1234")
    refute ObjectId.valid?("1234567890abcdef123")
    refute ObjectId.valid?("1234567890abcdef12345")
    refute ObjectId.valid?("1234567890abCdef1234")
    refute ObjectId.valid?("1234567890abXdef1234")
  end

  test "from_raw_bytes/1" do
    assert 0..19 |> Enum.to_list() |> ObjectId.from_raw_bytes() ==
             "000102030405060708090a0b0c0d0e0f10111213"

    assert 1..25 |> Enum.to_list() |> ObjectId.from_raw_bytes() ==
             "0102030405060708090a0b0c0d0e0f1011121314"
  end
end