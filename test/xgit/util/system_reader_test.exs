defmodule Xgit.Util.SystemReaderTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.Config
  alias Xgit.Util.SystemReader
  alias Xgit.Util.Time.MonotonicSystemClock

  test "hostname/1" do
    hostname = SystemReader.hostname()
    assert is_binary(hostname)
    refute hostname == ""
  end

  test "get_env/2" do
    user_env = SystemReader.get_env("USER")

    unless user_env == nil do
      assert is_binary(user_env)
      refute user_env == ""
    end
  end

  test "user_config/1" do
    _user_config = %Config{} = SystemReader.user_config()
  end

  test "current_time/1" do
    time = SystemReader.current_time()
    assert is_integer(time)
  end

  test "clock/1" do
    assert %MonotonicSystemClock{} = SystemReader.clock()
  end
end
