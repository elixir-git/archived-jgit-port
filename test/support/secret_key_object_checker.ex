# Defined here so it is in MIX_ENV=test compile path.
# Otherwise, we miss the window of opportunity for protocol consolidation.

defmodule Xgit.Lib.ObjectChecker.SecretKeyCheckerStrategy do
  @moduledoc false
  defstruct [:ignore_me]
end

defimpl Xgit.Lib.ObjectChecker.Strategy, for: Xgit.Lib.ObjectChecker.SecretKeyCheckerStrategy do
  alias Xgit.Errors.CorruptObjectError

  @impl Xgit.Lib.ObjectChecker.Strategy
  def check_commit!(_strategy, commit_data) do
    s = to_string(commit_data)

    if String.contains?(s, "mumble"), do: :mumble, else: :default
  end

  @impl Xgit.Lib.ObjectChecker.Strategy
  def check_blob!(_strategy, blob_data) do
    s = to_string(blob_data)

    if String.contains?(s, "secret_key"),
      do: raise(CorruptObjectError, why: "don't add a secret key"),
      else: :ok
  end
end
