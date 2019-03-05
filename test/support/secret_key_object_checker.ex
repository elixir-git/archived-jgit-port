# Defined here so it is in MIX_ENV=test compile path.
# Otherwise, we miss the window of opportunity for protocol consolidation.

defmodule Xgit.Lib.ObjectChecker.SecretKeyCheckerStrategy do
  @moduledoc false
  defstruct [:ignore_me]
end

defimpl Xgit.Lib.ObjectChecker.Strategy, for: Xgit.Lib.ObjectChecker.SecretKeyCheckerStrategy do
  alias Xgit.Errors.CorruptObjectError

  @impl Xgit.Lib.ObjectChecker.Strategy
  def check_commit!(_strategy, _commit_data), do: :default

  @impl Xgit.Lib.ObjectChecker.Strategy
  def check_blob!(_strategy, blob_data) do
    s = to_string(blob_data)

    if String.contains?(s, "secret_key"),
      do: raise(CorruptObjectError, why: "don't add a secret key"),
      else: :ok
  end

  @impl Xgit.Lib.ObjectChecker.Strategy
  def new_blob_object_checker(_strategy), do: nil
    # @Override
    # public BlobObjectChecker newBlobObjectChecker() {
    # 	return new BlobObjectChecker() {
    # 		private boolean containSecretKey;
    #
    # 		@Override
    # 		public void update(byte[] in, int offset, int len) {
    # 			String str = decode(in, offset, offset + len);
    # 			if (str.contains("secret_key")) {
    # 				containSecretKey = true;
    # 			}
    # 		}
    #
    # 		@Override
    # 		public void endBlob(AnyObjectId id)
    # 				throws CorruptObjectException {
    # 			if (containSecretKey) {
    # 				throw new CorruptObjectException(
    # 						"don't add a secret key");
    # 			}
    # 		}
    # 	};
    # }
end
