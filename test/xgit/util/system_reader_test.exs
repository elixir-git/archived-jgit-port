defmodule Xgit.Util.SystemReaderTest do
  use ExUnit.Case, async: true

  alias Xgit.Util.SystemReader

  test "hostname/1" do
    hostname = SystemReader.hostname(nil)
    assert is_binary(hostname)
    refute hostname == ""
  end

  test "get_env/2" do
    user_env = SystemReader.get_env(nil, "USER")

    unless user_env == nil do
      assert is_binary(user_env)
      refute user_env == ""
    end
  end

  test "current_time/1" do
    time = SystemReader.current_time(nil)
    assert is_integer(time)
  end
end
