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

defmodule Xgit.Test.MockObjectReader do
  @moduledoc false
  # Used for testing only.

  @enforce_keys [:objects]
  defstruct [:objects, :skip_default_object_size?]
end

defimpl Xgit.Lib.ObjectReader.Strategy, for: Xgit.Test.MockObjectReader do
  alias Xgit.Errors.MissingObjectError
  alias Xgit.Lib.AbbreviatedObjectId
  alias Xgit.Lib.SmallObjectLoader
  alias Xgit.Test.MockObjectReader

  def resolve(%MockObjectReader{objects: objects} = _reader, abbreviated_id) do
    objects
    |> Enum.filter(&object_matches_abbrev?(&1, abbreviated_id))
    |> Enum.map(fn {_object_id, object} -> object end)
  end

  defp object_matches_abbrev?({object_id, _object}, abbreviated_id),
    do: AbbreviatedObjectId.prefix_compare(abbreviated_id, object_id) == :eq

  def has_object?(%MockObjectReader{objects: objects} = _reader, object_id, _type_hint),
    do: Map.has_key?(objects, object_id)

  def open(%MockObjectReader{objects: objects} = _reader, object_id, type_hint) do
    case Map.get(objects, object_id) do
      %{type: type, data: data} ->
        %SmallObjectLoader{type: type, data: data}

      _ ->
        raise(MissingObjectError, object_id: object_id, type: type_hint)
    end
  end

  def object_size(
        %MockObjectReader{skip_default_object_size?: true} = _reader,
        _object_id,
        _type_hint
      ) do
    42
    # probably wrong, but useful for testing
  end

  def object_size(%MockObjectReader{objects: _objects} = _reader, _object_id, _type_hint),
    do: :default
end
