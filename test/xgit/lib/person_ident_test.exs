defmodule Xgit.Lib.PersonIdentTest do
  use ExUnit.Case

  alias Xgit.Lib.PersonIdent
  doctest Xgit.Lib.PersonIdent

  describe "sanitized/1" do
    test "strips whitespace and non-parseable characters from raw string" do
      assert PersonIdent.sanitized(" Baz>\n\u1234<Quux ") == "Baz\u1234Quux"
    end
  end

  describe "format_timezone/1" do
    test "formats as +/-hhmm" do
      assert PersonIdent.format_timezone(-120) == "-0200"
      assert PersonIdent.format_timezone(-690) == "-1130"
      assert PersonIdent.format_timezone(0) == "+0000"
      assert PersonIdent.format_timezone(150) == "+0230"
    end
  end
end
