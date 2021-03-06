# Copyright (C) 2010, Google Inc.
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/internal/storage/file/WriteConfig.java
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

defmodule Xgit.Storage.File.Internal.WriteConfig do
  @moduledoc false
  # INTERNAL: Parse some write configuration variables from config file.

  # TO DO: Cache section parser results like Config.SectionParser in jgit?
  # https://github.com/elixir-git/archived-jgit-port/issues/183

  alias Xgit.Lib.Config
  alias Xgit.Lib.ConfigConstants

  @type t :: %__MODULE__{
          compression: integer,
          fsync_object_files?: boolean,
          fsync_ref_files?: boolean
        }

  @enforce_keys [:compression, :fsync_object_files?, :fsync_ref_files?]
  defstruct [:compression, :fsync_object_files?, :fsync_ref_files?]

  @default_compression -1

  @spec from_config(config :: Config.t()) :: t
  def from_config(%Config{} = config) do
    %__MODULE__{
      compression:
        Config.get_int(
          config,
          ConfigConstants.config_core_section(),
          ConfigConstants.config_key_compression(),
          @default_compression
        ),
      fsync_object_files?: Config.get_boolean(config, "core", "fsyncobjectfiles", false),
      fsync_ref_files?: Config.get_boolean(config, "core", "fsyncreffiles", false)
    }
  end
end
