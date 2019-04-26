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

defmodule Xgit.Util.Time.ProposedTimestampTest do
  use ExUnit.Case, async: true

  alias Xgit.Util.Time.ProposedTimestamp
  alias Xgit.Test.MockProposedTime

  describe "read/2" do
    setup do
      mock_time = %MockProposedTime{time: 1_250_379_778_668_345}
      # time == Sat Aug 15 20:12:58 GMT-03:30 2009
      {:ok, mock_time: mock_time}
    end

    test ":seconds", %{mock_time: mock_time} do
      assert ProposedTimestamp.read(mock_time, :second) == 1_250_379_778
    end

    test ":millisecond", %{mock_time: mock_time} do
      assert ProposedTimestamp.read(mock_time, :millisecond) == 1_250_379_778_668
    end

    test ":microsecond", %{mock_time: mock_time} do
      assert ProposedTimestamp.read(mock_time, :microsecond) == 1_250_379_778_668_345
    end

    test "arbitrary divisor", %{mock_time: mock_time} do
      assert ProposedTimestamp.read(mock_time, 10_000) == 125_037_977_866
    end
  end
end
