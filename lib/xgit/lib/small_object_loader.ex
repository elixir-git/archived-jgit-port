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

defmodule Xgit.Lib.SmallObjectLoader do
  @moduledoc ~S"""
  Implements `Xgit.Lib.ObjectLoader` for cached byte lists.

  `Xgit.Lib.ObjectReader` implementations can fall back to this implementation
  when the  object's content is small enough to be accessed as a single byte list.
  """

  @typedoc ~S"""
  Contains the data to be loaded.

  ## Struct Members

  * `:type`: One of the `obj_*` values from `Xgit.Lib.Constants`.
  * `:data`: (byte list) The full content of the data. Should be "reasonably" small.
  """
  @type t :: %__MODULE__{type: Xgit.Lib.Constants.obj_type(), data: [byte]}

  @enforce_keys [:type, :data]
  defstruct [:type, :data]

  defimpl Xgit.Lib.ObjectLoader do
    alias Xgit.Lib.SmallObjectLoader

    @impl true
    def type(%SmallObjectLoader{type: type}), do: type

    @impl true
    def size(%SmallObjectLoader{data: data}), do: Enum.count(data)

    @impl true
    def large?(_), do: false

    @impl true
    def cached_bytes(%SmallObjectLoader{data: data}), do: data

    @impl true
    def stream(%SmallObjectLoader{data: data}), do: data
  end
end
