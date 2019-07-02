# Copyright (C) 2008-2009, Google Inc.
# Copyright (C) 2008, Jonas Fonseca <fonseca@diku.dk>
# Copyright (C) 2008, Marek Zawirski <marek.zawirski@gmail.com>
# Copyright (C) 2007, Robin Rosenberg <robin.rosenberg@dewire.com>
# Copyright (C) 2006-2008, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/ObjectLoader.java
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

defprotocol Xgit.Lib.ObjectLoader do
  @moduledoc ~S"""
  Protocol that allows for different storage representations of git objects.
  """

  @type t :: struct

  @doc ~S"""
  Get in-pack object type.

  See the `obj_*` functions in `Xgit.Lib.Constants`.
  """
  @spec type(loader :: t) :: 0..7
  def type(loader)

  @doc ~S"""
  Get the size of the object in bytes.
  """
  @spec size(loader :: t) :: non_neg_integer
  def size(loader)

  @doc ~S"""
  Return `true` if this object is too large to obtain as a byte array.

  If so, the caller should use a stream returned by `open_stream/1` to
  prevent overflowing the VM heap.
  """
  @spec large?(loader :: t) :: boolean
  def large?(loader)

  @doc ~S"""
  Obtain the (possibly cached) bytes of this object.

  This function offers direct access to the internal caches, potentially
  saving on data copies between the internal cache and higher level code.
  """
  @spec cached_bytes(loader :: t) :: [byte]
  def cached_bytes(loader)

  @doc ~S"""
  Obtain an `Enumerable` (typically a stream) to read this object's data.
  """
  @spec stream(loader :: t) :: Enumerable.t()
  def stream(loader)

  # PORTING NOTE: It is expected that the `copyTo` function in jgit's ObjectLoader
  # class can be mimiced by using `Stream.into/1`, so it's unnecessary to port it.
end
