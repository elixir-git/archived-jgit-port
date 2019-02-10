defmodule Xgit.Util.RawParseUtilsTest do
  use ExUnit.Case

  alias Xgit.Util.RawParseUtils, as: RPU

  @commit 'tree e3a1035abd2b319bb01e57d69b0ba6cab289297e\n' ++
            'parent 54e895b87c0768d2317a2b17062e3ad9f76a8105\n' ++
            'committer A U Thor <author@xample.com 1528968566 +0200\n' ++
            'gpgsig -----BEGIN PGP SIGNATURE-----\n' ++
            ' \n' ++
            ' wsBcBAABCAAQBQJbGB4pCRBK7hj4Ov3rIwAAdHIIAENrvz23867ZgqrmyPemBEZP\n' ++
            ' U24B1Tlq/DWvce2buaxmbNQngKZ0pv2s8VMc11916WfTIC9EKvioatmpjduWvhqj\n' ++
            ' znQTFyiMor30pyYsfrqFuQZvqBW01o8GEWqLg8zjf9Rf0R3LlOEw86aT8CdHRlm6\n' ++
            ' wlb22xb8qoX4RB+LYfz7MhK5F+yLOPXZdJnAVbuyoMGRnDpwdzjL5Hj671+XJxN5\n' ++
            ' SasRdhxkkfw/ZnHxaKEc4juMz8Nziz27elRwhOQqlTYoXNJnsV//wy5Losd7aKi1\n' ++
            ' xXXyUpndEOmT0CIcKHrN/kbYoVL28OJaxoBuva3WYQaRrzEe3X02NMxZe9gkSqA=\n' ++
            ' =TClh\n' ++
            ' -----END PGP SIGNATURE-----\n' ++
            'some other header\n\n' ++
            'commit message'

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

  test "next_lf/1" do
    assert RPU.next_lf('abc\ndef') == 'def'
    assert RPU.next_lf('xyz') == ''
  end

  test "next_lf/2" do
    assert RPU.next_lf('abc\ndef', ?c) == '\ndef'
    assert RPU.next_lf('abc\ndef', ?d) == 'def'
    assert RPU.next_lf('xyz', ?y) == 'z'
  end

  test "until_next_lf/1" do
    assert RPU.until_next_lf('abc\ndef') == 'abc'
    assert RPU.until_next_lf('xyz') == 'xyz'
  end

  test "until_next_lf/2" do
    assert RPU.until_next_lf('abc\ndef', ?c) == 'ab'
    assert RPU.until_next_lf('abc\ndef', ?d) == 'abc'
    assert RPU.until_next_lf('xyz', ?y) == 'x'
  end

  test "header_end/1" do
    Enum.reduce([45, 93, 148, 619, 637], @commit, fn drop_count, remaining_commit ->
      actual = RPU.header_end(remaining_commit)
      expected = Enum.drop(@commit, drop_count)
      assert actual == expected
      Enum.drop(actual, 1)
    end)
  end

  test "header_start/2" do
    assert RPU.header_start('some', @commit) == Enum.drop(@commit, 625)
    assert RPU.header_start('missing', @commit) == nil
    assert RPU.header_start('other', Enum.drop(@commit, 629)) == nil
    assert RPU.header_start('parens', @commit) == nil
    assert RPU.header_start('commit', @commit) == 'message'
  end

  test "author/1" do
    assert RPU.author(@commit) == nil

    commit_with_author =
      'tree e3a1035abd2b319bb01e57d69b0ba6cab289297e\n' ++
        'parent 54e895b87c0768d2317a2b17062e3ad9f76a8105\n' ++
        'author A U Thorax <author@xample.com 1528968566 +0200\n'

    assert RPU.author(commit_with_author) == 'A U Thorax <author@xample.com 1528968566 +0200\n'
  end

  test "committer/1" do
    assert RPU.committer(@commit) == Enum.drop(@commit, 104)

    commit_with_author =
      'tree e3a1035abd2b319bb01e57d69b0ba6cab289297e\n' ++
        'parent 54e895b87c0768d2317a2b17062e3ad9f76a8105\n' ++
        'author A U Thorax <author@xample.com 1528968566 +0200\n'

    assert RPU.committer(commit_with_author) == nil
  end

  test "tagger/1" do
    assert RPU.tagger(@commit) == nil

    commit_with_tagger =
      'tree e3a1035abd2b319bb01e57d69b0ba6cab289297e\n' ++
        'parent 54e895b87c0768d2317a2b17062e3ad9f76a8105\n' ++
        'tagger A U Thorax <author@xample.com 1528968566 +0200\n'

    assert RPU.tagger(commit_with_tagger) == 'A U Thorax <author@xample.com 1528968566 +0200\n'
  end

  test "encoding/1" do
    assert RPU.encoding(@commit) == nil

    commit_with_encoding =
      'tree e3a1035abd2b319bb01e57d69b0ba6cab289297e\n' ++
        'parent 54e895b87c0768d2317a2b17062e3ad9f76a8105\n' ++
        'encoding UTF-8\n'

    assert RPU.encoding(commit_with_encoding) == 'UTF-8\n'
  end

  test "decode/1" do
    assert RPU.decode([64, 65, 66]) == "@AB"
    assert RPU.decode([228, 105, 116, 105]) == "äiti"
    assert RPU.decode([195, 164, 105, 116, 105]) == "äiti"
    assert RPU.decode([66, 106, 246, 114, 110]) == "Björn"
    assert RPU.decode([66, 106, 195, 182, 114, 110]) == "Björn"
  end

  test "extract_binary_string/1" do
    assert RPU.extract_binary_string([64, 65, 66]) == "@AB"
    assert RPU.extract_binary_string([228, 105, 116, 105]) == "äiti"
    assert RPU.extract_binary_string([66, 106, 246, 114, 110]) == "Björn"
  end

  test "until_end_of_paragraph/1" do
    some = RPU.header_start('some', @commit)
    assert RPU.until_end_of_paragraph(some) == 'other header'
    assert RPU.until_end_of_paragraph('abc\n\rblah') == 'abc\n\rblah'
    assert RPU.until_end_of_paragraph('abc\r\n\r\nblah') == 'abc'
    assert RPU.until_end_of_paragraph('abc\n\nblah') == 'abc'
    assert RPU.until_end_of_paragraph('abc\r\nblah') == 'abc\r\nblah'
    assert RPU.until_end_of_paragraph('abc\n\r\n\rblah') == 'abc\n'
  end
end
