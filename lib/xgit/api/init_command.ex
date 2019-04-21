defmodule Xgit.Api.InitCommand do
  @moduledoc ~S"""
  Create an empty git repository or reinitalize an existing one.

  See [documentation for `git init` command](http://www.kernel.org/pub/software/scm/git/docs/git-init.html).

  Struct members:
  * `:dir` (optional, string): The directory associated with the init operation. If neither this
    not `:git_dir` are provided, we'll use the current directory.
  * `:git_dir` (optional, string): The repository meta directory (typically named `.git`).
  * `:bare?`(optional, boolean): Set to `true` if the repository should be bare (i.e. have
    no working directory)
  """

  defstruct dir: nil, git_dir: nil, bare?: false

  alias Xgit.Lib.Constants
  alias Xgit.Lib.ObjectDatabase
  alias Xgit.Lib.Repository
  alias Xgit.Storage.File.FileRepository
  alias Xgit.Storage.File.FileRepositoryBuilder
  alias Xgit.Util.SystemReader

  @doc ~S"""
  Performs the `init` command to create a file-based repository.

  Returns an `Xgit.Lib.Repository` process corresponding to the newly-created
  repository. The repository process will be linked to the calling process (`self()`).

  You may provide a list of options (`opts`) which will be passed through to the
  `GenServer.start_link/3` call.
  """
  def run(%__MODULE__{dir: dir, git_dir: git_dir, bare?: bare?}, opts \\ [])
      when (is_binary(dir) or is_nil(dir)) and (is_binary(git_dir) or is_nil(git_dir)) and
             is_boolean(bare?) do
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

    unless ObjectDatabase.exists?(object_database) do
      Repository.create!(repository, bare?)
    end

    repository
  end

  defp validate_dirs(nil = _dir, _git_dir, _bare?), do: :ok

  defp validate_dirs(dir, git_dir, true = _bare?) do
    if dir == git_dir do
      :ok
    else
      raise ArgumentError,
            "When initializing a bare repo with directory #{git_dir} and separate git-dir #{dir} specified both folders must point to the same location"
    end
  end

  defp validate_dirs(dir, git_dir, _bare?) do
    if dir == git_dir do
      raise ArgumentError,
            "When initializing a non-bare repo with directory #{git_dir} and separate git-dir #{
              dir
            } specified both folders should not point to the same location"
    else
      :ok
    end
  end

  defp set_bare?(%FileRepositoryBuilder{} = builder, true), do: %{builder | bare?: true}
  defp set_bare?(builder, _), do: builder

  defp set_git_dir(%FileRepositoryBuilder{} = builder, git_dir) when is_binary(git_dir),
    do: %{builder | git_dir: git_dir}

  defp set_git_dir(builder, nil), do: builder

  defp populate_dirs(builder, dir, bare?)

  defp populate_dirs(_builder, nil, _bare?) do
    raise "46"

    # if (bare)
    #   builder.setGitDir(directory);
    # else {
    #   builder.setWorkTree(directory);
    #   if (builder.gitDir == null)
    #     builder.setGitDir(new File(directory, Constants.DOT_GIT));
    # }
  end

  defp populate_dirs(%{git_dir: nil} = builder, _dir, bare?) do
    dir_str = SystemReader.get_env("user.dir") || "."

    d =
      if bare? do
        dir_str
      else
        Path.join(dir_str, Constants.dot_git())
      end

    %{builder | git_dir: d}
  end

  defp populate_dirs(builder, _dir, true = _bare?), do: builder

  defp populate_dirs(_builder, _dir, _bare?) do
    raise "69"
    # directory was not set but gitDir was set
    # String dStr = SystemReader.getInstance().getProperty(
    #     "user.dir"); //$NON-NLS-1$
    # if (dStr == null)
    #   dStr = "."; //$NON-NLS-1$
    # builder.setWorkTree(new File(dStr));
  end
end
