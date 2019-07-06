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

defmodule Xgit.Storage.File.Internal.WriteConfigTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.Config
  alias Xgit.Lib.ConfigConstants
  alias Xgit.Storage.File.Internal.WriteConfig

  setup do
    {:ok, config: Config.new()}
  end

  describe "from_config/1" do
    test "empty config", %{config: config} do
      assert WriteConfig.from_config(config) == %WriteConfig{
               compression: -1,
               fsync_object_files?: false,
               fsync_ref_files?: false
             }
    end

    test "explicit config", %{config: config} do
      Config.set_int(
        config,
        ConfigConstants.config_core_section(),
        ConfigConstants.config_key_compression(),
        42
      )

      Config.set_boolean(config, "core", "fsyncobjectfiles", true)
      Config.set_boolean(config, "core", "fsyncreffiles", true)

      assert WriteConfig.from_config(config) == %WriteConfig{
               compression: 42,
               fsync_object_files?: true,
               fsync_ref_files?: true
             }
    end
  end
end
