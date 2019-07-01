# Copyright (C) 2010, Chris Aniszczyk <caniszczyk@gmail.com>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/api/InitCommand.java
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

defmodule Xgit.Api.InitCommand do
  @moduledoc ~S"""
  Creates an empty git repository or reinitalizes an existing one.
  """

  defstruct dir: nil, git_dir: nil, bare?: false

  @typedoc ~S"""
  Describes the operation to be performed.

  ## Struct Members

  * `:dir` (optional, string): The directory associated with the init operation. If neither this
    not `:git_dir` are provided, we'll use the current directory.
  * `:git_dir` (optional, string): The repository meta directory (typically named `.git`).
  * `:bare?`(optional, boolean): Set to `true` if the repository should be bare (i.e. have
    no working directory)
  """
  @type t :: %__MODULE__{}

  alias Xgit.Lib.Constants
  alias Xgit.Lib.ObjectDatabase
  alias Xgit.Lib.Repository
  alias Xgit.Storage.File.FileRepository
  alias Xgit.Storage.File.FileRepositoryBuilder

  @doc ~S"""
  Creates a file-based repository.

  This is analogous to running the
  [`git init` command](http://www.kernel.org/pub/software/scm/git/docs/git-init.html).

  ## Parameters

  * `init_command` - See [Struct Members](#t:t/0-struct-members) above.

  ## Options

  Any options provided are passed to the `GenServer.start_link/3` call for the
  repository process.

  ## Return Values

  Returns a PID for the new repository. Use the `Xgit.Lib.Repository` module to
  interact with this repository. The repository process will be linked to the
  calling process (`self()`).

  Will raise an error if unable to create the repo.
  """
  @spec run!(init_command :: t, opts :: Keyword.t()) :: pid
  def run!(%__MODULE__{dir: dir, git_dir: git_dir, bare?: bare?}, opts \\ [])
      when (is_binary(dir) or is_nil(dir)) and (is_binary(git_dir) or is_nil(git_dir)) and
             is_boolean(bare?) and is_list(opts) do
    validate_dirs(dir, git_dir, bare?)

    builder =
      %FileRepositoryBuilder{}
      |> set_bare?(bare?)
      |> FileRepositoryBuilder.read_environment()
      |> set_git_dir(git_dir)
      |> populate_dirs(dir, bare?)
      |> FileRepositoryBuilder.setup!()

    {:ok, repository} = FileRepository.start_link(builder, opts)

    object_database = Repository.object_database!(repository)

    unless ObjectDatabase.exists?(object_database),
      do: Repository.create!(repository, bare?: bare?)

    repository
  end

  defp validate_dirs(nil = _dir, _git_dir, _bare?), do: :ok

  defp validate_dirs(_dir, nil = _git_dir, _bare?), do: :ok

  defp validate_dirs(dir, dir, true = _bare?), do: :ok

  defp validate_dirs(dir, git_dir, true = _bare?) do
    raise ArgumentError,
          "When initializing a bare repo with directory #{git_dir} and separate git-dir #{dir} specified both folders must point to the same location"
  end

  defp validate_dirs(dir, dir, _bare?) do
    raise ArgumentError,
          "When initializing a non-bare repo with directory #{dir} and separate git-dir #{dir} specified both folders should not point to the same location"
  end

  defp validate_dirs(_dir, _git_dir, _bare?), do: :ok

  defp set_bare?(%FileRepositoryBuilder{} = builder, true), do: %{builder | bare?: true}
  defp set_bare?(builder, _), do: builder

  defp set_git_dir(%FileRepositoryBuilder{} = builder, git_dir) when is_binary(git_dir),
    do: %{builder | git_dir: git_dir}

  defp set_git_dir(builder, nil), do: builder

  defp populate_dirs(builder, dir, bare?)

  defp populate_dirs(%{git_dir: nil} = builder, dir, true = _bare?) when is_binary(dir),
    do: %{builder | git_dir: dir}

  defp populate_dirs(%{git_dir: nil} = builder, dir, false = _bare?) when is_binary(dir),
    do: %{builder | git_dir: Path.join(dir, Constants.dot_git())}

  defp populate_dirs(builder, _dir, true = _bare?), do: builder

  defp populate_dirs(builder, dir, _bare?) when is_binary(dir),
    do: %{builder | work_tree: dir}

  defp populate_dirs(%{git_dir: nil, work_tree: nil}, nil, _bare?) do
    raise ArgumentError, "InitCommand: either dir or git_dir must be specified"
    # Fallback to current working directory is not allowed.
  end
end
