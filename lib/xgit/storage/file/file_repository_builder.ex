defmodule Xgit.Storage.File.FileRepositoryBuilder do
  @moduledoc ~S"""
  A module for finding and/or creating file-based repositories.

  Struct members:
  * `git_dir`: The `.git` directory storing the repository metadata.
  * `object_dir`: The directory storing the repository's objects.
  * `alternate_object_directories`: List of alternate object directories to search.
  * `bare?`: True only if the caller wants to force bare behavior.
  * `must_exist?`: True if the caller requires the repository to exist.
  * `work_tree`: The top level directory of the working files.
  * `index_file`: The local index file that is caching checked out file status.
  * `ceiling_directories`: A list of directories limiting the search for a Git repository.

  PORTING NOTE: Unlike the jgit implementation, this version has no setters or getters
  for the configuration options. Set up the struct directly and then call the
  functions on this module to set up the repository.

  PORTING NOTE: Unlike the jgit implementation, we do not have a polymorphic mechanism
  for repository builders. Implementations that use other storage mechanisms should
  be built independently.
  """

  defstruct git_dir: nil,
            object_dir: nil,
            alternate_object_directories: nil,
            bare?: false,
            must_exist?: false,
            work_tree: nil,
            index_file: nil,
            ceiling_directories: nil

  alias Xgit.Lib.Config
  alias Xgit.Lib.ConfigConstants
  alias Xgit.Lib.Constants
  alias Xgit.Lib.RepositoryCache.FileKey
  alias Xgit.Storage.File.FileBasedConfig
  alias Xgit.Util.SystemReader

  @doc ~S"""
  Read standard git environment variables and configure from those.

  This method tries to read the standard git environment variables, such as
  `GIT_DIR` and `GIT_WORK_TREE` to configure this builder struct. If a property
  is already set in the struct, the environment variable is not used.

  Returns an updated copy of the builder struct.
  """
  def read_environment(%__MODULE__{} = builder, system_reader \\ nil) do
    builder
    |> maybe_update_git_dir(system_reader)
    |> maybe_update_object_dir(system_reader)
    |> maybe_update_alternate_object_directories(system_reader)
    |> maybe_update_work_tree(system_reader)
    |> maybe_update_index_file(system_reader)
    |> maybe_update_ceiling_directories(system_reader)
  end

  defp maybe_update_git_dir(%__MODULE__{git_dir: nil} = builder, reader),
    do: %{builder | git_dir: SystemReader.get_env(reader, Constants.git_dir_key())}

  defp maybe_update_git_dir(builder, _), do: builder

  defp maybe_update_object_dir(%__MODULE__{object_dir: nil} = builder, reader),
    do: %{
      builder
      | object_dir: SystemReader.get_env(reader, Constants.git_object_directory_key())
    }

  defp maybe_update_object_dir(builder, _), do: builder

  defp maybe_update_alternate_object_directories(
         %__MODULE__{alternate_object_directories: nil} = builder,
         reader
       ) do
    case SystemReader.get_env(reader, Constants.git_alternate_object_directories_key()) do
      nil ->
        builder

      x ->
        %{builder | alternate_object_directories: String.split(x, ":")}
        # WINDOWS PORTING NOTE: Should be ";" for Windows.
    end
  end

  defp maybe_update_alternate_object_directories(builder, _), do: builder

  defp maybe_update_work_tree(%__MODULE__{work_tree: nil} = builder, reader),
    do: %{builder | work_tree: SystemReader.get_env(reader, Constants.git_work_tree_key())}

  defp maybe_update_work_tree(builder, _), do: builder

  defp maybe_update_index_file(%__MODULE__{index_file: nil} = builder, reader),
    do: %{builder | index_file: SystemReader.get_env(reader, Constants.git_index_file_key())}

  defp maybe_update_index_file(builder, _), do: builder

  defp maybe_update_ceiling_directories(%__MODULE__{ceiling_directories: nil} = builder, reader) do
    case SystemReader.get_env(reader, Constants.git_ceiling_directories_key()) do
      nil ->
        builder

      x ->
        %{builder | ceiling_directories: String.split(x, ":")}
        # WINDOWS PORTING NOTE: Should be ";" for Windows.
    end
  end

  defp maybe_update_ceiling_directories(builder, _), do: builder

  @doc ~S"""
  Finds the git directory by searching up the file system.

  Starts from the supplied directory path (or current working directory if `nil`)
  and scans up through the parent directory tree until a git repository is found.

  The search can be limited to specific spaces of the local filesystem by adding
  entries to `ceiling_directories`, or inheriting the list through a prior call
  to `read_environment/2`.

  Returns an updated builder struct with `:git_dir` populated if successful.
  """
  def find_git_dir(builder, current \\ nil)

  def find_git_dir(%__MODULE__{git_dir: dir} = builder, _current) when is_binary(dir),
    do: builder

  def find_git_dir(%__MODULE__{git_dir: nil} = builder, nil),
    do: find_git_dir(builder, File.cwd!())

  def find_git_dir(
        %__MODULE__{git_dir: nil, ceiling_directories: ceiling_directories} = builder,
        current
      ) do
    maybe_git_dir = Path.join(current, Constants.dot_git())
    parent = Path.dirname(current)

    cond do
      FileKey.contains_git_repository?(maybe_git_dir) ->
        %{builder | git_dir: maybe_git_dir}

      # PORTING NOTE: We are not yet supporting sym ref syntax.

      FileKey.contains_git_repository?(current) ->
        %{builder | git_dir: current}

      # current == parent is what happens when you call Path.dirname/1 on a file system root.
      current == parent ->
        builder

      ceiling_directories != nil && Enum.member?(ceiling_directories, current) ->
        builder

      true ->
        find_git_dir(builder, parent)
    end
  end

  @doc ~S"""
  Guess and populate all parameters not already defined.

  If an option was not set, the setup method will try to default the option
  based on other options. If insufficient information is available, an
  exception is thrown to the caller.
  """
  def setup!(%__MODULE__{} = builder) do
    builder
    |> require_git_dir_or_work_tree!()
    |> setup_git_dir()
    |> setup_work_tree()
    |> setup_internals()
  end

  # /**
  #  * Create a repository matching the configuration in this builder.
  #  * <p>
  #  * If an option was not set, the build method will try to default the option
  #  * based on other options. If insufficient information is available, an
  #  * exception is thrown to the caller.
  #  *
  #  * @return a repository matching this configuration. The caller is
  #  *         responsible to close the repository instance when it is no longer
  #  *         needed.
  #  * @throws java.lang.IllegalArgumentException
  #  *             insufficient parameters were set.
  #  * @throws java.io.IOException
  #  *             the repository could not be accessed to configure the rest of
  #  *             the builder's parameters.
  #  */
  # @SuppressWarnings({ "unchecked", "resource" })
  # public R build() throws IOException {
  #   PORTING NOTE: This should move to FileRepository module to break dependency cycle.
  #   R repo = (R) new FileRepository(setup());
  #   if (isMustExist() && !repo.getObjectDatabase().exists())
  #     throw new RepositoryNotFoundException(getGitDir());
  #   return repo;
  # }

  # Require either `git_dir` or `work_tree` to be set.
  defp require_git_dir_or_work_tree!(%__MODULE__{git_dir: nil, work_tree: nil}) do
    raise ArgumentError, "One of git_dir or work_tree must be provided."
  end

  defp require_git_dir_or_work_tree!(builder), do: builder

  # Perform standard git_dir initialization.
  defp setup_git_dir(%__MODULE__{git_dir: nil, work_tree: work_tree} = builder)
       when is_binary(work_tree) do
    dot_git = Path.join(work_tree, Constants.dot_git())

    if File.regular?(dot_git),
      do: raise(RuntimeError, "sym ref .git file not yet supported"),
      else: %{builder | git_dir: dot_git}
  end

  defp setup_git_dir(%__MODULE__{} = builder), do: builder

  # Perform standard work-tree initialization.
  defp setup_work_tree(%__MODULE__{bare?: true} = builder), do: builder

  defp setup_work_tree(%__MODULE__{bare?: false} = builder) do
    %__MODULE__{bare?: bare?} = builder = guess_work_tree!(builder)

    if bare?,
      do: builder,
      else: setup_work_tree_from_metadata_dir(builder)
  end

  defp setup_work_tree_from_metadata_dir(builder) do
    # If after guessing we're still not bare, we must have
    # a metadata directory to hold the repository. Assume
    # it's at the work tree.

    builder
    # |> missing_git_dir_from_work_tree_parent()  # see comment below
    |> missing_index_file_from_git_dir()
  end

  # PORTING NOTE: Figure out if this case is ever reachable.
  # From what I can tell, the equivalent code in jgit is unreachable
  # since we previously have called setup_git_dir (setupGitDir in jgit).
  # I can't construct a case where git_dir is nil by this stage.
  # defp missing_git_dir_from_work_tree_parent(
  #        %__MODULE__{git_dir: nil, work_tree: work_tree} = builder
  #      )
  #      when is_binary(work_tree) do
  #   %{builder | git_dir: Path.dirname(work_tree)}
  # end
  #
  # defp missing_git_dir_from_work_tree_parent(%__MODULE__{} = builder), do: builder

  defp missing_index_file_from_git_dir(%__MODULE__{index_file: nil, git_dir: git_dir} = builder)
       when is_binary(git_dir) do
    %{builder | index_file: Path.join(git_dir, "index")}
  end

  defp missing_index_file_from_git_dir(%__MODULE__{} = builder), do: builder

  defp setup_internals(%__MODULE__{object_dir: nil, git_dir: git_dir} = builder)
       when is_binary(git_dir) do
    %{builder | object_dir: Path.join(git_dir, "objects")}
    # PORTING NOTE: We lost the fs.resolve from
    #   setObjectDirectory(safeFS().resolve(getGitDir(), "objects"));
  end

  defp setup_internals(builder), do: builder

  # Parse and load the repository-specific configuration.
  #
  # Reads `#{git_dir}/config` or returns an empty configuration
  # if `git_dir` was not set.

  # PORTING NOTE: Figure out if this case is ever reachable.
  # From what I can tell, the equivalent code in jgit is unreachable
  # since we previously have called setup_git_dir (setupGitDir in jgit).
  # I can't construct a case where git_dir is nil by this stage.
  # defp load_config(%__MODULE__{git_dir: nil}), do: Config.new()

  defp load_config(%__MODULE__{git_dir: git_dir}) when is_binary(git_dir) do
    # We only want the repository's configuration file, and not
    # the user file, as these parameters must be unique to this
    # repository and not inherited from other files.
    config_path = Path.join(git_dir, Constants.config())
    config = FileBasedConfig.config_for_path(config_path)

    try do
      Config.load(config)
      config
    rescue
      e ->
        message = Exception.message(e)
        raise ArgumentError, "Repository config file #{config_path} invalid #{message}"
    end
  end

  defp guess_work_tree!(%__MODULE__{git_dir: git_dir, work_tree: nil} = builder) do
    config = load_config(builder)

    path =
      Config.get_string(
        config,
        ConfigConstants.config_core_section(),
        ConfigConstants.config_key_worktree()
      )

    cond do
      # If set, core.worktree wins.
      is_binary(path) ->
        %{builder | work_tree: Path.expand(path, git_dir)}

      # If core.bare is set, honor its value. Assume work_tree is
      # the parent directory of the repository.
      is_binary(
        Config.get_string(
          config,
          ConfigConstants.config_core_section(),
          ConfigConstants.config_key_bare()
        )
      ) ->
        work_tree_from_explicit_bare_config(builder, config)

      # No value for the "bare" flag, but git_dir is named ".git":
      # use the parent of the directory.
      Path.basename(git_dir) == Constants.dot_git() ->
        %{builder | work_tree: Path.dirname(git_dir)}

      # None of the above apply: We have to assume we are bare.
      true ->
        set_bare(builder)
    end
  end

  defp guess_work_tree!(builder), do: builder

  defp work_tree_from_explicit_bare_config(%__MODULE__{git_dir: git_dir} = builder, config) do
    if Config.get_boolean(
         config,
         ConfigConstants.config_core_section(),
         ConfigConstants.config_key_bare(),
         true
       ),
       do: set_bare(builder),
       else: %{builder | work_tree: Path.dirname(git_dir)}
  end

  defp set_bare(%__MODULE__{} = builder),
    do: %{builder | index_file: nil, work_tree: nil, bare?: true}
end
