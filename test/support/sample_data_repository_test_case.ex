# Copyright (C) 2009, Google Inc.
# Copyright (C) 2008-2009, Jonas Fonseca <fonseca@diku.dk>
# Copyright (C) 2007-2009, Robin Rosenberg <robin.rosenberg@dewire.com>
# Copyright (C) 2006-2007, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/test/resources/SampleDataRepositoryTestCase.java
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

defmodule Xgit.Test.SampleDataRepositoryTestCase do
  @moduledoc ~S"""
  Test case which includes C git generated pack files for testing.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Xgit.Test.LocalDiskRepositoryTestCase
      alias Xgit.Test.RepositoryTestCase
    end
  end

  alias Xgit.Internal.Storage.File.ObjectDirectory
  alias Xgit.Lib.Repository
  alias Xgit.Test.RepositoryTestCase

  def setup do
    %{db: repo} = params = RepositoryTestCase.setup_test!()
    copy_c_git_test_packs(repo)
    {:ok, params}
  end

  @packs [
    "pack-34be9032ac282b11fa9babdc2b2a93ca996c9c2f",
    "pack-df2982f284bbabb6bdb59ee3fcc6eb0983e20371",
    "pack-9fb5b411fe6dfa89cc2e6b89d2bd8e5de02b5745",
    "pack-546ff360fe3488adb20860ce3436a2d6373d2796",
    "pack-cbdeda40019ae0e6e789088ea0f51f164f489d14",
    "pack-e6d07037cbcf13376308a0a995d1fa48f8f76aaa",
    "pack-3280af9c07ee18a87705ef50b0cc4cd20266cf12"
  ]

  @fixtures_dir Path.expand("../../fixtures", __DIR__)

  defp copy_c_git_test_packs(repo) do
    pack_dir =
      repo
      |> Repository.object_database!()
      |> ObjectDirectory.pack_directory()

    Enum.each(@packs, fn pack ->
      File.copy!(Path.join(@fixtures_dir, "#{pack}.pack"), Path.join(pack_dir, "#{pack}.pack"))
      File.copy!(Path.join(@fixtures_dir, "#{pack}.idx"), Path.join(pack_dir, "#{pack}.idx"))
    end)

    File.copy!(
      Path.join(@fixtures_dir, "packed-refs"),
      Path.join(Repository.git_dir!(repo), "packed-refs")
    )
  end
end
