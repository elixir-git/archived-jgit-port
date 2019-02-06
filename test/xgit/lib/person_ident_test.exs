defmodule Xgit.Lib.PersonIdentTest do
  use ExUnit.Case

  alias Xgit.Lib.PersonIdent
  doctest Xgit.Lib.PersonIdent

  describe "sanitized/1" do
    test "strips whitespace and non-parseable characters from raw string" do
      assert PersonIdent.sanitized(" Baz>\n\u1234<Quux ") == "Baz\u1234Quux"
    end
  end
end
