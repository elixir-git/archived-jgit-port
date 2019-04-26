# Copyright (C) 2019, Eric Scouten <eric+xgit@scouten.com>
#
# This program and the accompanying materials are made available
# under the terms of the Eclipse Distribution License v1.0 which
# accompanies this distribution, is reproduced below, and is
# available at http://www.eclipse.org/org/documents/edl-v10.php
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# - Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above
#   copyright notice, this list of conditions and the following
#   disclaimer in the documentation and/or other materials provided
#   with the distribution.
#
# - Neither the name of the Eclipse Foundation, Inc. nor the
#   names of its contributors may be used to endorse or promote
#   products derived from this software without specific prior
#   written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
