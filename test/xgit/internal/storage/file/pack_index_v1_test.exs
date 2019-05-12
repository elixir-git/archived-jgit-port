# Copyright (C) 2008, Imran M Yousuf <imyousuf@smartitengineering.com>
# Copyright (C) 2008, Marek Zawirski <marek.zawirski@gmail.com>
# Copyright (C) 2009, Matthias Sohn <matthias.sohn@sap.com>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/internal/storage/file/PackIndexV1Test.java
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

defmodule Xgit.Internal.Storage.File.PackIndexV1Test do
  use ExUnit.Case, async: true

  alias Xgit.Internal.Storage.File.PackIndex
  alias Xgit.Internal.Storage.File.PackIndex.Entry
  # alias Xgit.Internal.Storage.File.PackIndexV1

  defp path_for_pack_34be9032 do
    Path.expand("../../../../fixtures/pack-34be9032ac282b11fa9babdc2b2a93ca996c9c2f.idx", __DIR__)
  end

  test "expect results for pack 34be9032" do
    objects_in_pack_34be9032 =
      path_for_pack_34be9032()
      |> PackIndex.open()
      |> Enum.map(fn %Entry{name: name} -> name end)

    assert Enum.to_list(objects_in_pack_34be9032) == [
             "4b825dc642cb6eb9a060e54bf8d69288fbee4904",
             "540a36d136cf413e4b064c2b0e0a4db60f77feab",
             "5b6e7c66c276e7610d4a73c70ec1a1f7c1003259",
             "6ff87c4664981e4397625791c8ea3bbb5f2279a3",
             "82c6b885ff600be425b4ea96dee75dca255b69e7",
             "902d5476fa249b7abc9d84c611577a81381f0327",
             "aabf2ffaec9b497f0950352b3e582d73035c2035",
             "c59759f143fb1fe21c197981df75a7ee00290799"
           ]
  end

  # @Override
  # public File getFileForPackdf2982f28() {
  #   return JGitTestUtil.getTestResourceFile(
  #                   "pack-df2982f284bbabb6bdb59ee3fcc6eb0983e20371.idx");
  # }
  #
  # /**
  #  * Verify CRC32 - V1 should not index anything.
  #  *
  #  * @throws MissingObjectException
  #  */
  # @Override
  # @Test
  # public void testCRC32() throws MissingObjectException {
  #   assertFalse(smallIdx.hasCRC32Support());
  #   try {
  #     smallIdx.findCRC32(ObjectId
  #         .fromString("4b825dc642cb6eb9a060e54bf8d69288fbee4904"));
  #     fail("index V1 shouldn't support CRC");
  #   } catch (UnsupportedOperationException x) {
  #     // expected
  #   }
  # }
end
