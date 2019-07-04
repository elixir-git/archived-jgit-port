# Copyright (C) 2009, Google Inc.
# Copyright (C) 2009, Robin Rosenberg <robin.rosenberg@dewire.com>
# Copyright (C) 2009, Yann Simon <yann.simon.fr@gmail.com>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.junit/src/org/eclipse/jgit/junit/MockSystemReader.java
#
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

defmodule Xgit.Test.MockSystemReader do
  @moduledoc false
  # Used for testing only.

  alias Xgit.Lib.Config

  @type t :: %__MODULE__{
          hostname: String.t(),
          env: map,
          user_config: Config.t() | nil,
          system_config: Config.t() | nil,
          time_agent: pid | nil
        }

  defstruct hostname: "fake.host.example.com",
            env: %{},
            user_config: nil,
            system_config: nil,
            time_agent: nil

  alias Xgit.Lib.Config
  alias Xgit.Test.MockConfigStorage

  @spec new() :: t
  def new do
    {:ok, time_agent} = Agent.start_link(fn -> 1_250_379_778_668_000 end)
    # ^ time is Sat Aug 15 20:12:58 GMT-03:30 2009

    %__MODULE__{
      user_config: Config.new(storage: %MockConfigStorage{}),
      system_config: Config.new(storage: %MockConfigStorage{}),
      time_agent: time_agent
    }
  end

  # Adjust the current time by _n_ seconds.
  @spec tick(t, integer) :: integer
  def tick(%{time_agent: time_agent}, seconds) do
    Agent.get_and_update(time_agent, fn existing_time ->
      new_time = existing_time + seconds * 1_000_000
      {new_time, new_time}
    end)
  end
end

defimpl Xgit.Util.SystemReader, for: Xgit.Test.MockSystemReader do
  alias Xgit.Lib.Config
  alias Xgit.Test.MockSystemReader

  @impl true
  def hostname(%{hostname: hostname}), do: hostname

  @impl true
  def get_env(%{env: env}, variable), do: Map.get(env, variable)

  @impl true
  def user_config(%MockSystemReader{user_config: user_config} = _reader, nil = _parent_config),
    do: user_config

  def user_config(%MockSystemReader{user_config: user_config} = _reader, %Config{storage: nil}),
    do: user_config

  # Assume in this case that the idle system config will never be written to.
  # This is probably for testing.

  @impl true
  def system_config(
        %MockSystemReader{system_config: system_config} = _reader,
        nil = _parent_config
      ) do
    system_config
  end

  @impl true
  def current_time(%{time_agent: time_agent}) do
    time_agent
    |> Agent.get(& &1)
    |> Kernel.div(1000)
  end

  @impl true
  def clock(reader), do: reader

  @impl true
  def timezone_at_time(_, _time), do: -210

  @impl true
  def timezone(_), do: -210
  # Offset in the mock is GMT-03:30.
end

defimpl Xgit.Util.Time.MonotonicClock, for: Xgit.Test.MockSystemReader do
  # We impmlement the MonotonicClock protocol directly on MockSystemReader
  # because it needs to access "current time" state from MockSystemReader's
  # time agent.

  alias Xgit.Test.MockSystemReader
  alias Xgit.Util.SystemReader

  @impl true
  def propose(%MockSystemReader{} = system_reader) do
    t = SystemReader.current_time(system_reader)
    %Xgit.Test.MockProposedTime{time: t}
  end
end
