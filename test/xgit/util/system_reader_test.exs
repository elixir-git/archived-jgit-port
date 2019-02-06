defmodule Xgit.Util.SystemReaderTest do
  use ExUnit.Case

  alias Xgit.Util.SystemReader

  @default_reader Xgit.Util.SystemReader.Default.instance()

  test "hostname/1" do
    hostname = SystemReader.hostname(@default_reader)
    assert is_binary(hostname)
    refute hostname == ""
  end

  test "get_env/2" do
    user_env = SystemReader.get_env(@default_reader, "USER")

    unless user_env == nil do
      assert is_binary(user_env)
      refute user_env == ""
    end
  end

  test "current_time/1" do
    time = SystemReader.current_time(@default_reader)
    assert is_integer(time)
  end
end
