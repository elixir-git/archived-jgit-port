defmodule Xgit.Util.RawParseUtilsTest do
  use ExUnit.Case

  alias Xgit.Util.RawParseUtils, as: RPU

  test "parse_base_10/1" do
    assert RPU.parse_base_10('abc') == {0, 'abc'}
    assert RPU.parse_base_10('0abc') == {0, 'abc'}
    assert RPU.parse_base_10('99') == {99, ''}
    assert RPU.parse_base_10('+99x') == {99, 'x'}
    assert RPU.parse_base_10('  -42 ') == {-42, ' '}
    assert RPU.parse_base_10('   xyz') == {0, 'xyz'}
  end

  test "parse_hex_int16/1" do
    assert RPU.parse_hex_int16('00FFasd') == {255, 'asd'}
    assert RPU.parse_hex_int16('03FF') == {1023, ''}
    assert RPU.parse_hex_int16('03ff') == {1023, ''}
  end

  test "parse_hex_int32/1" do
    assert RPU.parse_hex_int32('80000001xzx') == {2_147_483_649, 'xzx'}
    assert RPU.parse_hex_int32('000003Ff') == {1023, ''}
  end

  test "parse_hex_int64/1" do
    assert RPU.parse_hex_int64('8000000420000001abc') == {9_223_372_054_571_515_905, 'abc'}
    assert RPU.parse_hex_int64('E0000004200f0001') == {16_140_901_082_213_580_801, ''}
  end

  test "parse_hex_int4/1" do
    assert RPU.parse_hex_int4('84') == {8, '4'}
    assert RPU.parse_hex_int4('E') == {14, ''}
  end

  test "parse_timezone_offset/1" do
    assert RPU.parse_timezone_offset('0') == {0, ''}
    assert RPU.parse_timezone_offset('') == {0, ''}
    assert RPU.parse_timezone_offset('-0315X') == {-195, 'X'}
    assert RPU.parse_timezone_offset('+0400abc') == {240, 'abc'}
  end

  test "next/2" do
    assert RPU.next('abcddef', ?d) == 'def'
    assert RPU.next('abcd', ?d) == ''
    assert RPU.next('abcd', ?x) == ''
  end
end
