defmodule Xgit.Lib.ObjectIdTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.Constants
  alias Xgit.Lib.ObjectId

  doctest Xgit.Lib.ObjectId

  test "zero/0" do
    zero = ObjectId.zero()
    assert is_binary(zero)
    assert String.length(zero) == 40
    assert ObjectId.valid?(zero)
    assert String.match?(zero, ~r/^0+$/)
  end

  test "valid?/1" do
    assert ObjectId.valid?("1234567890abcdef12341234567890abcdef1234")
    refute ObjectId.valid?("1234567890abcdef1231234567890abcdef1234")
    refute ObjectId.valid?("1234567890abcdef123451234567890abcdef1234")
    refute ObjectId.valid?("1234567890abCdef12341234567890abcdef1234")
    refute ObjectId.valid?("1234567890abXdef12341234567890abcdef1234")

    assert ObjectId.valid?('1234567890abcdef12341234567890abcdef1234')
    refute ObjectId.valid?('1234567890abcdef1231234567890abcdef1234')
    refute ObjectId.valid?('1234567890abcdef123451234567890abcdef1234')
    refute ObjectId.valid?('1234567890abCdef12341234567890abcdef1234')
    refute ObjectId.valid?('1234567890abXdef12341234567890abcdef1234')

    refute ObjectId.valid?(nil)
  end

  test "from_raw_bytes/1" do
    assert 0..19 |> Enum.to_list() |> ObjectId.from_raw_bytes() ==
             "000102030405060708090a0b0c0d0e0f10111213"

    assert 1..25 |> Enum.to_list() |> ObjectId.from_raw_bytes() ==
             "0102030405060708090a0b0c0d0e0f1011121314"
  end

  test "from_hex_charlist/1" do
    assert ObjectId.from_hex_charlist('1234567890abcdef12341234567890abcdef1234') ==
             {'1234567890abcdef12341234567890abcdef1234', []}

    assert ObjectId.from_hex_charlist('1234567890abcdef1231234567890abcdef1234') == false

    assert ObjectId.from_hex_charlist('1234567890abcdef123451234567890abcdef1234') ==
             {'1234567890abcdef123451234567890abcdef123', '4'}

    assert ObjectId.from_hex_charlist('1234567890abCdef12341234567890abcdef1234') == false

    assert ObjectId.from_hex_charlist('1234567890abXdef12341234567890abcdef1234') == false
  end

  test "id_for/2" do
    data = 'test025 some data, more than 16 bytes to get good coverage'

    assert ObjectId.id_for(Constants.obj_blob(), data) ==
             "4f561df5ecf0dfbd53a0dc0f37262fef075d9dde"
  end
end
