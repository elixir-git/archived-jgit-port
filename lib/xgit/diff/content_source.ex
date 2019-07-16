# Copyright (C) 2010, Google Inc.
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/diff/ContentSource.java
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

defmodule Xgit.Diff.ContentSource do
  @moduledoc ~S"""
  Supplies the content of a file for `Xgit.Diff.DiffFormatter` (not yet ported).

  *PORTING NOTE:* In jgit, `ContentSource` is an abstract class. In Xgit, it is
  a module which switches behavior based on whether it is passed a
  `Xgit.TreeWalk.WorkingTreeIterator` (not yet ported) or a struct for which
  the `Xgit.Lib.ObjectReader.Strategy` protocol is implemented.
  """

  alias Xgit.Lib.Constants
  alias Xgit.Lib.ObjectId
  alias Xgit.Lib.ObjectLoader
  alias Xgit.Lib.ObjectReader

  @type t :: ObjectReader.t()
  # PORTING NOTE: add WorkingTreeIterator.t(), whenever that is defined.
  # https://github.com/elixir-git/archived-jgit-port/issues/124

  @doc ~S"""
  Determine the size of the object.

  ## Parameters

  `path` is the path of the file, relative to the root of the repository.

  `object_id` is the blob ID of the file, if known.

  ## Return Value

  The size of the object in bytes.
  """
  @spec size(source :: t, path :: String.t(), object_id :: ObjectId.t()) :: non_neg_integer()
  def size(source, _path, object_id),
    do: ObjectReader.object_size(source, object_id, Constants.obj_blob())

  @doc ~S"""
  Open the object.

  ## Parameters

  `path` is the path of the file, relative to the root of the repository.

  `object_id` is the blob ID of the file, if known.

  ## Return Value

  Returns a struct that implements `Xgit.Lib.ObjectLoader` protocol. This struct
  can be used to supply the content of the file. The loader must be used before
  another loader can be obtained from this same source.
  """
  @spec open(source :: t, path :: String.t(), object_id :: ObjectId.t()) :: ObjectLoader.t()
  def open(source, _path, object_id),
    do: ObjectReader.open(source, object_id, Constants.obj_blob())
end
