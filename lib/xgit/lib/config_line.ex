# Copyright (C) 2010, Mathias Kinzler <mathias.kinzler@sap.com>
# Copyright (C) 2009, Constantine Plotnikov <constantine.plotnikov@gmail.com>
# Copyright (C) 2007, Dave Watson <dwatson@mimvista.com>
# Copyright (C) 2008-2010, Google Inc.
# Copyright (C) 2009, Google, Inc.
# Copyright (C) 2009, JetBrains s.r.o.
# Copyright (C) 2007-2008, Robin Rosenberg <robin.rosenberg@dewire.com>
# Copyright (C) 2006-2008, Shawn O. Pearce <spearce@spearce.org>
# Copyright (C) 2008, Thad Hughes <thadh@thad.corp.google.com>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/ConfigLine.java
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

defmodule Xgit.Lib.ConfigLine do
  @moduledoc ~S"""
  A line in a git `Config` file.

  Struct members:
  * `prefix`: The text content before entry.
  * `section`: The section name for the entry.
  * `subsection`: Subsection name.
  * `name`: The key name.
  * `value`: The value.
  * `suffix`: The text content after entry.
  * `included_from`: The source from which this line was included from.
  """

  defstruct [:prefix, :section, :subsection, :name, :value, :suffix, :included_from]

  @doc ~S"""
  Return `true` if this config line matches the section and subection.
  """
  def match_section?(%__MODULE__{section: sec1, subsection: sub1}, sec2, sub2),
    do: match_ignore_case?(sec1, sec2) && sub1 == sub2

  @doc ~S"""
  Return `true` if this config line matches the section, subection, and key.
  """
  def match?(%__MODULE__{section: sec1, subsection: sub1, name: key1}, sec2, sub2, key2),
    do: match_ignore_case?(sec1, sec2) && sub1 == sub2 && match_ignore_case?(key1, key2)

  @doc ~S"""
  Return `true` if this config line matches the section and key.
  """
  def match?(%__MODULE__{section: sec1, name: key1}, sec2, key2),
    do: match_ignore_case?(sec1, sec2) && match_ignore_case?(key1, key2)

  defp match_ignore_case?(s1, s2), do: maybe_downcase(s1) == maybe_downcase(s2)

  defp maybe_downcase(nil), do: nil
  defp maybe_downcase(s), do: String.downcase(s)
end

defimpl String.Chars, for: Xgit.Lib.ConfigLine do
  def to_string(%Xgit.Lib.ConfigLine{
        section: section,
        subsection: subsection,
        name: name,
        value: value
      }),
      do:
        "#{section_str(section)}#{subsection_str(subsection)}#{name_str(name)}#{value_str(value)}"

  defp section_str(nil), do: "<empty>"
  defp section_str(s), do: s

  defp subsection_str(nil), do: ""
  defp subsection_str(s), do: ".#{s}"

  defp name_str(nil), do: ""
  defp name_str(s), do: ".#{s}"

  defp value_str(nil), do: ""
  defp value_str(s), do: "=#{s}"
end
