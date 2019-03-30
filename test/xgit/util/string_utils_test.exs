defmodule Xgit.Util.StringUtilsTest do
  use ExUnit.Case, async: true

  alias Xgit.Util.StringUtils

  test "empty_or_nil?/1" do
    assert StringUtils.empty_or_nil?(nil) == true
    assert StringUtils.empty_or_nil?("") == true
    assert StringUtils.empty_or_nil?("mumble") == false
  end
end
