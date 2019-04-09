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

  describe "user_config/1" do
    test "no base config" do
      assert %Config{} = SystemReader.user_config()
    end

    test "with base config" do
      base_config =
        Config.new()
        |> Config.set_string("my", "somename", "false")

      user_config = SystemReader.user_config(nil, base_config)
      assert Config.get_string(user_config, "my", "somename") == "false"
    end
  end

  test "system_reader/1" do
    assert %Config{storage: nil} = SystemReader.system_config()
  end

  test "current_time/1" do
    time = SystemReader.current_time()
    assert is_integer(time)
  end

  test "clock/1" do
    assert %MonotonicSystemClock{} = SystemReader.clock()
  end

  test "timezone_at_time/2" do
    assert SystemReader.timezone_at_time(1_250_379_778_668) == 0
    # PORTING NOTE: Elixir does not have the depth of time-zone knowledge that is
    # available in Java. For now, the abstraction is present, but the default
    # system reader will always return 0 (GMT).
  end

  test "timezone/1" do
    assert SystemReader.timezone() == 0
    # PORTING NOTE: Elixir does not have the depth of time-zone knowledge that is
    # available in Java. For now, the abstraction is present, but the default
    # system reader will always return 0 (GMT).
  end
end
