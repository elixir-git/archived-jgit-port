# Copyright (C) 2010, Google Inc.
# Copyright (C) 2008, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/ObjectIdRef.java
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

defmodule Xgit.Lib.ObjectIdRef do
  @moduledoc ~S"""
  An `Xgit.Lib.Ref` that points directly at an object ID.
  """

  @typedoc ~S"""
  An implementation of `Xgit.Lib.Ref` for a specific object ID.

  ## Struct Members

  * `name`: (string) name of this ref
  * `storage`: method used to store this ref (See `t:Xgit.Lib.Ref.storage/0`.)
  * `object_id`: (optional, string) current value of the ref. May be `nil` to indicate a ref that
    does not exist yet.
  * `peeled?`: (optional, boolean) `true` if the ref has been peeled (implied if
    `peeled_object_id` is not `nil`)
  * `peeled_object_id`: (optional, string) current peeled value of the ref.
    If `nil`, indicates that the object ref hasn't been peeled yet.
  * `tag?`: (optional, boolean ) `true` if the peeled value points to a tag
  * `update_index`: (integer or `:undefined`) number that increases with each ref update.
    Set to `:undefined` if the storage doesn't support versioning.
  """
  @type t :: %__MODULE__{
          name: String.t(),
          storage: Xgit.Lib.Ref.storage(),
          object_id: String.t() | nil,
          peeled?: boolean | nil,
          peeled_object_id: String.t() | nil,
          tag?: boolean | nil,
          update_index: non_neg_integer | :undefined
        }

  @enforce_keys [:name, :storage]
  defstruct [
    :name,
    :storage,
    :object_id,
    :peeled?,
    :peeled_object_id,
    :tag?,
    update_index: :undefined
  ]

  defimpl Xgit.Lib.Ref do
    alias Xgit.Lib.ObjectIdRef

    @impl true
    def name(%ObjectIdRef{name: name}), do: name

    @impl true
    def symbolic?(_), do: false

    @impl true
    def leaf(ref), do: ref

    @impl true
    def target(ref), do: ref

    @impl true
    def object_id(%ObjectIdRef{object_id: object_id}), do: object_id

    @impl true
    def peeled_object_id(%ObjectIdRef{tag?: true, peeled_object_id: peeled_object_id}),
      do: peeled_object_id

    def peeled_object_id(_), do: nil

    @impl true
    def peeled?(%ObjectIdRef{peeled?: true}), do: true
    def peeled?(%ObjectIdRef{peeled_object_id: nil}), do: false
    def peeled?(_), do: true

    @impl true
    def storage(%ObjectIdRef{storage: storage}), do: storage

    @impl true
    def update_index(%ObjectIdRef{update_index: update_index})
        when is_integer(update_index) and update_index > 0,
        do: update_index

    def update_index(_), do: raise(RuntimeError, "update_index is invalid")
  end

  defimpl String.Chars do
    @impl true
    def to_string(%Xgit.Lib.ObjectIdRef{
          name: name,
          object_id: object_id,
          update_index: update_index
        }),
        do: "Ref[#{name}=#{object_id}(#{update_index})]"
  end
end
