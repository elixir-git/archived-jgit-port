# Copyright (C) 2007, Dave Watson <dwatson@mimvista.com>
# Copyright (C) 2006-2007, Robin Rosenberg <robin.rosenberg@dewire.com>
# Copyright (C) 2006-2007, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/CommitBuilder.java
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

defmodule Xgit.Lib.CommitBuilder do
  @moduledoc ~S"""
  Constructs a commit recording the state of a project.

  Applications should use this module when they need to manually construct a
  commit and want precise control over its fields. For a higher-level interface
  see `Xgit.Api.CommitCommand` (not yet ported).

  To read a commit object, use the `Xgit.RevWalk` module and obtain an
  `Xgit.RevWalk.RevCommit` struct by calling `parse_commit`.

  ## TO DO: UNIMPLEMENTED

  * encodings other than UTF-8
  * GPG signatures

  https://github.com/elixir-git/xgit/issues/171
  """

  @typedoc ~S"""
  Represents a commit being built.

  ## Struct Members

  * `tree_id`: (string) SHA hash of tree structure
  * `parent_ids`: (list of string) parents of this commit
  * `author`: (`Xgit.Lib.PersonIdent`)
  * `committer`: (`Xgit.Lib.PersonIdent`)
  * `message`: (string) commit message
  * `encoding`: (atom) encoding (currently must be `:utf8`)
  """
  @type t :: %__MODULE__{
          tree_id: String.t(),
          parent_ids: [String.t()] | nil,
          author: Xgit.Lib.PersonIdent.t(),
          committer: Xgit.Lib.PersonIdent.t(),
          message: String.t() | nil,
          encoding: :utf8
        }

  @enforce_keys [:tree_id, :author, :committer]

  defstruct tree_id: nil,
            parent_ids: [],
            author: nil,
            committer: nil,
            message: nil,
            encoding: :utf8

  # /**
  #  * Add a parent onto the end of the parent list.
  #  *
  #  * @param additionalParent
  #  *            new parent to add onto the end of the current parent list.
  #  */
  # public void addParentId(AnyObjectId additionalParent) {
  #   if (parentIds.length == 0) {
  #     setParentId(additionalParent);
  #   } else {
  #     ObjectId[] newParents = new ObjectId[parentIds.length + 1];
  #     System.arraycopy(parentIds, 0, newParents, 0, parentIds.length);
  #     newParents[parentIds.length] = additionalParent.copy();
  #     parentIds = newParents;
  #   }
  # }

  @doc ~S"""
  Format this builder's state as a commit object.

  ## Return Value

  A byte list containing this object in the canonical commit format, suitable
  for storage in a repository.
  """
  @spec build(commit :: t) :: iolist
  def build(%__MODULE__{
        tree_id: tree_id,
        parent_ids: parent_ids,
        author: author,
        committer: committer,
        encoding: encoding,
        message: message
      }) do
    iolist = [
      ["tree ", tree_id, "\n"],
      build_parent_ids(parent_ids),
      ["author ", to_string(author), "\n"],
      ["committer ", to_string(committer), "\n"],
      # build_gpg_signature(gpg_signature),
      build_encoding(encoding),
      "\n",
      build_message(message)
    ]

    iolist
    |> :erlang.iolist_to_binary()
    |> :binary.bin_to_list()
  end

  defp build_parent_ids(parent_ids) do
    parent_ids
    |> Enum.map(&["parent ", &1, "\n"])
    |> Enum.join()
  end

  # defp build_gpg_signature(gpg_signature) do
  #   # private static final byte[] hgpgsig = Constants.encodeASCII("gpgsig"); //$NON-NLS-1$
  #   # if (getGpgSignature() != null) {
  #   #   os.write(hgpgsig);
  #   #   os.write(' ');
  #   #   writeGpgSignatureString(getGpgSignature().toExternalString(), os);
  #   #   os.write('\n');
  #   # }
  # end

  # /**
  #  * Writes signature to output as per <a href=
  #  * "https://github.com/git/git/blob/master/Documentation/technical/signature-format.txt#L66,L89">gpgsig
  #  * header</a>.
  #  * <p>
  #  * CRLF and CR will be sanitized to LF and signature will have a hanging
  #  * indent of one space starting with line two.
  #  * </p>
  #  *
  #  * @param in
  #  *            signature string with line breaks
  #  * @param out
  #  *            output stream
  #  * @throws IOException
  #  *             thrown by the output stream
  #  * @throws IllegalArgumentException
  #  *             if the signature string contains non 7-bit ASCII chars
  #  */
  # static void writeGpgSignatureString(String in, OutputStream out)
  #     throws IOException, IllegalArgumentException {
  #   for (int i = 0; i < in.length(); ++i) {
  #     char ch = in.charAt(i);
  #     if (ch == '\r') {
  #       if (i + 1 < in.length() && in.charAt(i + 1) == '\n') {
  #         out.write('\n');
  #         out.write(' ');
  #         ++i;
  #       } else {
  #         out.write('\n');
  #         out.write(' ');
  #       }
  #     } else if (ch == '\n') {
  #       out.write('\n');
  #       out.write(' ');
  #     } else {
  #       // sanity check
  #       if (ch > 127)
  #         throw new IllegalArgumentException(MessageFormat
  #             .format(JGitText.get().notASCIIString, in));
  #       out.write(ch);
  #     }
  #   }
  # }

  defp build_encoding(:utf8), do: []

  # defp build_encoding(encoding) do
  #   # private static final byte[] hencoding = Constants.encodeASCII("encoding"); //$NON-NLS-1$
  #   # os.write(hencoding);
  #   # os.write(' ');
  #   # os.write(Constants.encodeASCII(getEncoding().name()));
  #   # os.write('\n');
  # end

  defp build_message(nil), do: []
  defp build_message(message), do: message

  # defimpl String.Chars do
  #   @impl true
  #   def to_string(%Xgit.Lib.CommitBuilder{
  #         tree_id: tree_id,
  #         parent_ids: parent_ids,
  #         author: author,
  #         committer: committer,
  #         encoding: encoding,
  #         message: message
  #       }) do
  #     iolist = [
  #       "Commit={\n",
  #       ["tree ", tree_id, "\n"],
  #       parent_ids_to_str(parent_ids),
  #       ["author ", to_string(author), "\n"],
  #       ["committer ", to_string(committer), "\n"],
  #       # ["gpg_signature", gpg_sig_to_str(gpg_signature), "\n"],
  #       encoding_to_str(encoding),
  #       "\n",
  #       message_to_str(message)
  #     ]
  #
  #     :erlang.iolist_to_binary(iolist)
  #   end
  #
  #   defp parent_ids_to_str(parent_ids) do
  #     parent_ids
  #     |> Enum.map(&"parent #{&1}\n")
  #     |> Enum.join()
  #   end
  #
  #   # defp gpg_sig_to_str(gpg_signature) do
  #   #   (if non-nil ...)
  #   #   r.append("gpgSignature ");
  #   #   r.append(gpgSignature != null ? gpgSignature.toString() : "NOT_SET");
  #   #   r.append("\n");
  #   # end
  #
  #   defp encoding_to_str(nil), do: []
  #   defp encoding_to_str(:utf8), do: []
  #
  #   # defp encoding_to_str(other_encoding) do
  #   #   # r.append("gpgSignature ");
  #   #   # r.append(gpgSignature != null ? gpgSignature.toString() : "NOT_SET");
  #   #   # r.append("\n");
  #   # end
  #
  #   defp message_to_str(nil), do: []
  #   defp message_to_str(message), do: message
  # end
end
