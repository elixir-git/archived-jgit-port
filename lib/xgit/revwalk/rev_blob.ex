# Copyright (C) 2009, Google Inc.
# Copyright (C) 2008, Marek Zawirski <marek.zawirski@gmail.com>
# Copyright (C) 2008, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/revwalk/RevBlob.java
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

defmodule Xgit.RevWalk.RevBlob do
  @moduledoc ~S"""
  Represents a binary file or a symbolic link.
  """

  @typedoc ~S"""
  Implements `Xgit.RevWalk.RevObject.Object` for a binary file or symbolic link.

  ## Struct Members

  * `flags`: (`MapSet`) flags associated with this object
  * `id`: (string) object ID
  """
  @type t :: %__MODULE__{flags: MapSet.t(), id: String.t()}

  @enforce_keys [:id]
  defstruct [{:flags, MapSet.new()}, :id]

  defimpl Xgit.RevWalk.RevObject.Object do
    alias Xgit.Lib.Constants

    @impl true
    def object_id(%{id: id}), do: id

    @impl true
    def parsed?(%{flags: %MapSet{} = flags}), do: MapSet.member?(flags, :parsed)

    @impl true
    def type(_), do: Constants.obj_blob()

    @impl true
    def flags(%{flags: %MapSet{} = flags}), do: flags

    @impl true
    def add_flags(%{flags: %MapSet{} = flags} = object, %MapSet{} = new_flags),
      do: %{object | flags: MapSet.union(flags, new_flags)}

    @impl true
    def remove_flags(%{flags: %MapSet{} = flags} = object, %MapSet{} = new_flags),
      do: %{object | flags: MapSet.difference(flags, new_flags)}

    # TO DO: Finish implementation of RevObject and related modules.
    # https://github.com/elixir-git/xgit/issues/181

    # @Override
    # void parseHeaders(RevWalk walk) throws MissingObjectException,
    #     IncorrectObjectTypeException, IOException {
    #   if (walk.reader.has(this))
    #     flags |= PARSED;
    #   else
    #     throw new MissingObjectException(this, getType());
    # }
    #
    # @Override
    # void parseBody(RevWalk walk) throws MissingObjectException,
    #     IncorrectObjectTypeException, IOException {
    #   if ((flags & PARSED) == 0)
    #     parseHeaders(walk);
    # }
  end
end
