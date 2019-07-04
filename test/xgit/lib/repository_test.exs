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

defmodule Xgit.Lib.RepositoryTest do
  use ExUnit.Case, async: true

  alias Xgit.Errors.NoWorkTreeError
  alias Xgit.Lib.Repository

  import ExUnit.CaptureLog

  doctest Xgit.Lib.Repository

  test "handles unexpected calls" do
    {:ok, pid} = __MODULE__.BogusRepository.start_link()
    assert is_pid(pid)

    assert capture_log(fn ->
             assert {:error, :unknown_message} = GenServer.call(pid, :bogus)
           end) =~ "[warn]  Repository received unrecognized call :bogus"

    assert Process.alive?(pid)
  end

  test "raises NoWorkTreeError for index_file!/1 call" do
    {:ok, pid} = __MODULE__.BogusRepository.start_link()
    assert is_pid(pid)

    assert_raise NoWorkTreeError,
                 "Bare Repository has neither a working tree, nor an index",
                 fn ->
                   Repository.index_file!(pid)
                 end
  end

  test "raises NoWorkTreeError for object_database!/1 call" do
    {:ok, pid} = __MODULE__.BogusRepository.start_link()
    assert is_pid(pid)

    assert_raise NoWorkTreeError,
                 "Bare Repository has neither a working tree, nor an index",
                 fn ->
                   Repository.object_database!(pid)
                 end
  end

  defmodule BogusRepository do
    @moduledoc false

    use Xgit.Lib.Repository

    @spec start_link() :: GenServer.on_start()
    def start_link, do: Repository.start_link(__MODULE__, nil, [])

    @impl true
    def init(_), do: {:ok, nil}

    @impl true
    def handle_config(_), do: {:ok, nil, nil}

    @impl true
    def handle_create(_, _opts), do: {:ok, nil}
  end
end
