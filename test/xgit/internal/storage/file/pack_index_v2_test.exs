# Copyright (C) 2008, Imran M Yousuf <imyousuf@smartitengineering.com>
# Copyright (C) 2008, Marek Zawirski <marek.zawirski@gmail.com>
# Copyright (C) 2009, Matthias Sohn <matthias.sohn@sap.com>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/internal/storage/file/PackIndexV2Test.java
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

defmodule Xgit.Internal.Storage.File.PackIndexV2Test do
  use ExUnit.Case, async: true

  alias Xgit.Internal.Storage.File.PackIndex
  alias Xgit.Internal.Storage.File.PackIndex.Entry

  defp path_for_pack_34be9032 do
    # aka "small index"
    Path.expand(
      "../../../../fixtures/pack-34be9032ac282b11fa9babdc2b2a93ca996c9c2f.idxV2",
      __DIR__
    )
  end

  defp path_for_pack_df2982f28 do
    # aka "dense index"
    Path.expand(
      "../../../../fixtures/pack-df2982f284bbabb6bdb59ee3fcc6eb0983e20371.idxV2",
      __DIR__
    )
  end

  test "expect results for pack 34be9032" do
    objects_in_pack_34be9032 =
      path_for_pack_34be9032()
      |> PackIndex.open()
      |> Enum.map(fn %Entry{name: name} -> name end)

    assert objects_in_pack_34be9032 == [
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

  test "expect (partial) results for pack df2982f28" do
    objects_in_pack_df2982f28 =
      path_for_pack_df2982f28()
      |> PackIndex.open()
      |> Stream.drop_while(fn %Entry{name: name} ->
        name != "0a3d7772488b6b106fb62813c4d6d627918d9181"
      end)
      |> Stream.drop(1)
      |> Stream.take(3)
      |> Enum.map(fn %Entry{name: name} -> name end)

    assert objects_in_pack_df2982f28 == [
             "1004d0d7ac26fbf63050a234c9b88a46075719d3",
             "10da5895682013006950e7da534b705252b03be6",
             "1203b03dc816ccbb67773f28b3c19318654b0bc8"
           ]
  end

  describe "get_object_id_at_index/2" do
    test "offsets match output of iterator (small index)" do
      pack_index =
        path_for_pack_34be9032()
        |> PackIndex.open()

      pack_index
      |> Enum.with_index()
      |> Enum.each(fn {%Entry{name: name}, index} ->
        assert PackIndex.get_object_id_at_index(pack_index, index) == name
      end)
    end

    test "offsets match output of iterator (dense index)" do
      pack_index =
        path_for_pack_df2982f28()
        |> PackIndex.open()

      pack_index
      |> Enum.with_index()
      |> Enum.each(fn {%Entry{name: name}, index} ->
        assert PackIndex.get_object_id_at_index(pack_index, index) == name
      end)
    end
  end

  describe "get_offset_at_index/2" do
    test "offsets match output of iterator (small index)" do
      pack_index =
        path_for_pack_34be9032()
        |> PackIndex.open()

      pack_index
      |> Enum.with_index()
      |> Enum.each(fn {%Entry{offset: offset}, index} ->
        assert PackIndex.get_offset_at_index(pack_index, index) == offset
      end)
    end

    test "offsets match output of iterator (dense index)" do
      pack_index =
        path_for_pack_df2982f28()
        |> PackIndex.open()

      pack_index
      |> Enum.with_index()
      |> Enum.each(fn {%Entry{offset: offset}, index} ->
        assert PackIndex.get_offset_at_index(pack_index, index) == offset
      end)
    end
  end

  describe "find_offset/2" do
    test "offsets match output of iterator (small index)" do
      pack_index =
        path_for_pack_34be9032()
        |> PackIndex.open()

      pack_index
      |> Enum.each(fn %Entry{name: name, offset: offset} ->
        assert PackIndex.find_offset(pack_index, name) == offset
      end)
    end

    test "offsets match output of iterator (dense index)" do
      pack_index =
        path_for_pack_df2982f28()
        |> PackIndex.open()

      pack_index
      |> Enum.each(fn %Entry{name: name, offset: offset} ->
        assert PackIndex.find_offset(pack_index, name) == offset
      end)
    end
  end

  test "CRC32 indexing" do
    pack_index =
      path_for_pack_34be9032()
      |> PackIndex.open()

    assert PackIndex.has_crc32_support?(pack_index) == true

    assert PackIndex.crc32_checksum_for_object(
             pack_index,
             "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
           ) == 0xC2B64258

    assert PackIndex.crc32_checksum_for_object(
             pack_index,
             "540a36d136cf413e4b064c2b0e0a4db60f77feab"
           ) == 0x72AD57C2

    assert PackIndex.crc32_checksum_for_object(
             pack_index,
             "5b6e7c66c276e7610d4a73c70ec1a1f7c1003259"
           ) == 0xFF10A479

    assert PackIndex.crc32_checksum_for_object(
             pack_index,
             "6ff87c4664981e4397625791c8ea3bbb5f2279a3"
           ) == 0x34B27DDC

    assert PackIndex.crc32_checksum_for_object(
             pack_index,
             "82c6b885ff600be425b4ea96dee75dca255b69e7"
           ) == 0x4743F1E4

    assert PackIndex.crc32_checksum_for_object(
             pack_index,
             "902d5476fa249b7abc9d84c611577a81381f0327"
           ) == 0x640B358B

    assert PackIndex.crc32_checksum_for_object(
             pack_index,
             "aabf2ffaec9b497f0950352b3e582d73035c2035"
           ) == 0x2A17CB5E

    assert PackIndex.crc32_checksum_for_object(
             pack_index,
             "c59759f143fb1fe21c197981df75a7ee00290799"
           ) == 0x0B3B5BA6
  end
end
