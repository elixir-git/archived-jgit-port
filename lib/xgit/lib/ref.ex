# Copyright (C) 2006-2008, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/Ref.java
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

defprotocol Xgit.Lib.Ref do
  @moduledoc ~S"""
  Pairing of a name and the object ID it currently has.

  A ref in git is (more or less) a variable that holds a single object identifier.
  The object identifier can be any valid git object (blob, tree, commit,
  annotated tag, ...).

  The ref name has the attributes of the ref that was asked for as well as the
  ref it was resolved to for symbolic refs plus the object id it points to and
  (for tags) the peeled target object id, i.e. the tag resolved recursively
  until a non-tag object is referenced.
  """

  @typedoc ~S"""
  Location where a ref is stored. One of the following values:

  * `:new`: The ref does not exist yet. Updating it may create it. Creation is
    likely to choose `:loose` storage.

  * `:loose`: The ref is stored in a file by itself. Updating this ref affects
    only this ref.

  * `:packed`: The ref is stored in the `packed-refs` file with other refs.
    Updating this ref requires rewriting the file, with perhaps many other refs
    being included at the same time.

  * `:loose_packed`: The ref is both `:loose` and `:packed`. Updating this ref
    requires only updating the loose file, but deletion requires updating both
    the loose file and the packed refs file.

  * `:network`: The ref came from a network advertisement and storage is unknown.
    This ref cannot be updated without git-aware support on the remote side, as
    git-aware code consolidate the remote refs and reported them to this process.
  """
  @type storage :: :new | :loose | :packed | :loose_packed | :network

  @type t :: struct

  @doc ~S"What this ref is called within the repository."
  @spec name(ref :: t) :: String.t()
  def name(ref)

  @doc ~S"""
  Is this reference a symbolic reference?

  A symbolic reference does not have its own object ID value, but instead
  points to another ref in the same database and always uses that other
  reference's value as its own.
  """
  @spec symbolic?(ref :: t) :: boolean()
  def symbolic?(ref)

  @doc ~S"""
  Recursively traverse target references until `symbolic?/1` is `false`.
  """
  @spec leaf(ref :: t) :: Ref.t()
  def leaf(ref)

  @doc ~S"""
  Get the reference this reference points to or `ref` itself.

  If `symbolic?/1` is `true` this method returns the reference it directly names,
  which might not be the leaf reference, but could be another symbolic reference.

  If this is a leaf level reference that contains its own object ID, this function
  returns `ref`.
  """
  @spec target(ref :: t) :: Ref.t()
  def target(ref)

  @doc ~S"""
  Cached value of this ref.

  Returns the value of this ref at the last time we read it. May be `nil` to
  indicate a ref that does not exist yet or a symbolic ref pointing to an unborn
  branch.
  """
  @spec object_id(ref :: t) :: ObjectId.t()
  def object_id(ref)

  @doc ~S"""
  Cached value of `ref^{}` (the ref peeled to commit).

  ## Return Value

  If this ref is an annotated tag, return the id of the commit (or tree or blob) that
  the annotated tag refers to.

  If this ref does not refer to an annotated tag, return `nil`.
  """
  @spec peeled_object_id(ref :: t) :: ObjectID.t() | nil
  def peeled_object_id(ref)

  @doc ~S"""
  Returns `true` if the ref represents a peeled tag.
  """
  @spec peeled?(ref :: t) :: boolean
  def peeled?(ref)

  @doc ~S"""
  How was this ref obtained?

  The current storage model of a ref may influence how the ref must be updated
  or deleted from the repository.

  See `t:storage/0`.
  """
  @spec storage(ref :: t) :: storage
  def storage(ref)

  @doc ~S"""
  Indicator of the relative order between updates of a specific reference
  name. A number that increases when a reference is updated.

  With symbolic references, the update index refers to updates of the symbolic
  reference itself. For example, if `HEAD` points to `refs/heads/master`, then
  the update index for `exact_ref("HEAD")` will only increase when `HEAD` changes
  to point to another ref, regardless of how many times `refs/heads/master` is updated.

  Should not be used unless the `Xgit.Lib.RefDatabase` that instantiated the ref
  supports versioning. (See `RefDatabase.has_versioning?/1`.)

  Can throw `RuntimeError` if the creator of the instance (e.g. `Xgit.Lib.RefDatabase`)
  doesn't support versioning.
  """
  @spec update_index(ref :: t) :: number
  def update_index(ref)
end
