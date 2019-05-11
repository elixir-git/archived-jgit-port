# Copyright (C) 2009, Constantine Plotnikov <constantine.plotnikov@gmail.com>
# Copyright (C) 2007, Dave Watson <dwatson@mimvista.com>
# Copyright (C) 2009, Google Inc.
# Copyright (C) 2009, JetBrains s.r.o.
# Copyright (C) 2008-2009, Robin Rosenberg <robin.rosenberg@dewire.com>
# Copyright (C) 2008, Shawn O. Pearce <spearce@spearce.org>
# Copyright (C) 2008, Thad Hughes <thadh@thad.corp.google.com>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/storage/file/FileBasedConfig.java
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

defmodule Xgit.Storage.File.FileBasedConfig do
  @moduledoc ~S"""
  Implements `Xgit.Lib.Config.Storage` by storing the config data in a file.
  (This is the typical case.)

  Struct members:
  * `path`: Path to the config file.
  * `snapshot`: An `Xgit.Internal.Storage.File.FileSnapshot` for this path.
  """
  @enforce_keys [:path, :snapshot]
  defstruct [:path, :snapshot]

  alias Xgit.Internal.Storage.File.FileSnapshot
  alias Xgit.Lib.Config

  @doc ~S"""
  Create a configuration for a file path with no default fallback.

  Options are as for `Xgit.Lib.Config.new/1`.
  """
  def config_for_path(path, options \\ []) when is_binary(path) do
    Config.new(
      Keyword.put(options, :storage, %__MODULE__{path: path, snapshot: snapshot_for_path(path)})
    )
  end

  defp snapshot_for_path(path) do
    if File.exists?(path),
      do: FileSnapshot.save(path),
      else: FileSnapshot.missing_file()
  end

  # /** {@inheritDoc} */
  # @Override
  # protected boolean notifyUponTransientChanges() {
  #   // we will notify listeners upon save()
  #   return false;
  # }

  # /** {@inheritDoc} */
  # @SuppressWarnings("nls")
  # @Override
  # public String toString() {
  #   return getClass().getSimpleName() + "[" + getFile().getPath() + "]";
  # }

  @doc ~S"""
  Returns `true` if the currently-loaded configuration file is outdated.
  """
  def outdated?(%Config{storage: %__MODULE__{path: path, snapshot: snapshot}}),
    do: FileSnapshot.modified?(snapshot, path)

  def outdated?(_other_config), do: false
  # All other forms of configs are never considered outdated.

  # /**
  #  * {@inheritDoc}
  #  *
  #  * @since 4.10
  #  */
  # @Override
  # protected byte[] readIncludedConfig(String relPath)
  #     throws ConfigInvalidException {
  #   final File file;
  #   if (relPath.startsWith("~/")) { //$NON-NLS-1$
  #     file = fs.resolve(fs.userHome(), relPath.substring(2));
  #   } else {
  #     file = fs.resolve(configFile.getParentFile(), relPath);
  #   }
  #
  #   if (!file.exists()) {
  #     return null;
  #   }
  #
  #   try {
  #     return IO.readFully(file);
  #   } catch (IOException ioe) {
  #     throw new ConfigInvalidException(MessageFormat
  #         .format(JGitText.get().cannotReadFile, relPath), ioe);
  #   }
  # }

  defimpl Xgit.Lib.Config.Storage do
    alias Xgit.Lib.Config

    @doc ~S"""
    Load the configuration as a git text-style configuration file.

    If the file does not exist, this configuration is cleared, and thus
    behaves the same as though the file exists, but is empty.
    """
    def load(%Xgit.Storage.File.FileBasedConfig{path: path}, config) do
      # PORTING NOTE: jgit's implementation contains a lot of logic to handle
      # cases where the file has moved, becomes stale, retrying in the event
      # of failure, etc. For now, I am not porting those cases. Consider revisiting
      # this later.

      if File.exists?(path) do
        contents = File.read!(path)
        Config.from_text(config, contents)
      else
        Config.clear(config)
      end

      :ok
    end

    @doc ~S"""
    Save the configuration as a git text-style configuration file.
    """
    def save(%Xgit.Storage.File.FileBasedConfig{path: path}, config) do
      # PORTING NOTE: jgit's implementation contains logic to ensure that there
      # aren't multiple simultaneous writers to the file and that the UTF-8 BOM
      # is written only if a BOM was present in the original file. For now, I am
      # not porting those cases. Consider revisiting this later.

      File.write!(path, Config.to_text(config))
      :ok
    end
  end
end
