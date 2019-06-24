# Copyright (C) 2008, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/revwalk/RevObject.java
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

# PORTING NOTE: Port as a protocol for unparsed placeholder vs specific (parsed) types.

defmodule Xgit.RevWalk.RevObject do
  @moduledoc ~S"""
  Shared infrastructure for objects accessed during revision walking.
  """

  alias Xgit.Lib.Constants

  defprotocol Object do
    @moduledoc ~S"""
    Objects made accessible via revision walking will implement this protocol.
    """
    alias Xgit.Lib.ObjectId

    @type t :: term

    @doc ~S"""
    Return the name (object ID) of this object.
    """
    @spec object_id(object :: t) :: ObjectId.t()
    def object_id(object)

    @doc ~S"""
    Return `true` if the object has been parsed.
    """
    @spec parsed?(object :: t) :: boolean
    def parsed?(object)

    @doc ~S"""
    Return the git object type of the object.

    This will be one of the `obj_*` types defined in `Constants`.
    """
    @spec type(object :: t) :: integer
    def type(object)

    @doc ~S"""
    Return the set of flags that has been set on this object.
    """
    @spec flags(object :: t) :: MapSet.t()
    def flags(object)

    @doc ~S"""
    Returns a new instance of this object with one or more flags added.
    """
    @spec add_flags(object :: t, flags :: [atom]) :: t
    def add_flags(object, flags)

    @doc ~S"""
    Returns a new instance of this object with one or more flags removed.
    """
    @spec remove_flags(object :: t, flags :: [atom]) :: t
    def remove_flags(object, flags)
  end

  defmodule Unparsed do
    @moduledoc ~S"""
    An object whose contents have not yet been parsed.

    ## Struct Members

    * `flags`: (MapSet) flags associated with this object
    * `id`: (String) object ID
    * `type`: (integer) object type (one of `obj_*` constants)
    """
    @enforce_keys [:id, :type]
    defstruct [{:flags, MapSet.new()}, :id, :type]

    defimpl Xgit.RevWalk.RevObject.Object do
      @impl true
      def object_id(%{id: id}), do: id

      @impl true
      def parsed?(_object), do: false

      @impl true
      def type(%{type: type}), do: type

      @impl true
      def flags(%{flags: %MapSet{} = flags}), do: flags

      @impl true
      def add_flags(%{flags: %MapSet{} = flags} = object, %MapSet{} = new_flags),
        do: %{object | flags: MapSet.union(flags, new_flags)}

      @impl true
      def remove_flags(%{flags: %MapSet{} = flags} = object, %MapSet{} = new_flags),
        do: %{object | flags: MapSet.difference(flags, new_flags)}
    end

    defimpl String.Chars do
      @impl true
      defdelegate to_string(object), to: Xgit.RevWalk.RevObject
    end
  end

  # abstract void parseHeaders(RevWalk walk) throws MissingObjectException,
  #     IncorrectObjectTypeException, IOException;
  #
  # abstract void parseBody(RevWalk walk) throws MissingObjectException,
  #     IncorrectObjectTypeException, IOException;

  @doc ~S"""
  Return the name (object ID) of this object.
  """
  defdelegate object_id(object), to: Object

  @doc ~S"""
  Return the git object type of the object.

  This will be one of the `obj_*` types defined in `Constants`.
  """
  defdelegate type(object), to: Object

  @doc ~S"""
  Returns `true` if the given flag has been set on this object.
  """
  def has_flag?(object, flag) when is_atom(flag) do
    flags = Object.flags(object)
    MapSet.member?(flags, flag)
  end

  @doc ~S"""
  Returns `true` if any of the flags in the list has been set on this object.
  """
  def has_any_flag?(object, %MapSet{} = test_flags) do
    flags = Object.flags(object)

    test_flags
    |> MapSet.intersection(flags)
    |> Enum.empty?()
    |> invert()
  end

  defp invert(b), do: !b

  @doc ~S"""
  Returns `true` if all of the flags in the list have been set on this object.
  """
  def has_all_flags?(object, %MapSet{} = test_flags) do
    flags = Object.flags(object)

    test_flags
    |> MapSet.intersection(flags)
    |> MapSet.equal?(test_flags)
  end

  @doc ~S"""
  Add a flag to this object.
  """
  def add_flag(object, flag) when is_atom(flag), do: add_flags(object, MapSet.new([flag]))

  @doc ~S"""
  Add a set of flags to this object.
  """
  defdelegate add_flags(object, flags), to: Object

  @doc ~S"""
  Remove a flag from this object.
  """
  def remove_flag(object, flag) when is_atom(flag), do: remove_flags(object, MapSet.new([flag]))

  @doc ~S"""
  Remove a set of flags from this object.
  """
  defdelegate remove_flags(object, flags), to: Object

  @doc ~S"""
  Render a string from any struct that implements the `RevObject.Object` protocol.

  Intended to be called by those struct modules.
  """
  def to_string(rev_object) do
    type_str =
      rev_object
      |> type()
      |> Constants.type_string()

    name = object_id(rev_object)
    flags_str = core_flags_str(rev_object)

    "#{type_str} #{name} #{flags_str}"
  end

  defp core_flags_str(rev_object) do
    flag_str(rev_object, :topo_delay, "o") <>
      flag_str(rev_object, :temp_mark, "t") <>
      flag_str(rev_object, :rewrite, "r") <>
      flag_str(rev_object, :uninteresting, "u") <>
      flag_str(rev_object, :seen, "s") <>
      flag_str(rev_object, :parsed, "p")
  end

  defp flag_str(rev_object, flag, flag_char) do
    if has_flag?(rev_object, flag),
      do: flag_char,
      else: "-"
  end
end