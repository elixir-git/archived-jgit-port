defmodule Xgit.Errors.CorruptObjectErrorTest do
  use ExUnit.Case, async: true

  alias Xgit.Errors.CorruptObjectError

  test "constructs error message with object ID" do
    try do
      raise CorruptObjectError, id: "foo", why: "it's bogus"
    rescue
      x in CorruptObjectError ->
        assert x.message == "Object foo is corrupt: it's bogus"
    end
  end

  test "constructs error message without object ID" do
    try do
      raise CorruptObjectError, why: "it's bogus"
    rescue
      x in CorruptObjectError ->
        assert x.message == "Object (unknown) is corrupt: it's bogus"
    end
  end
end
