defmodule Xgit.Lib.SmallObjectLoaderTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.Constants
  alias Xgit.Lib.ObjectLoader
  alias Xgit.Lib.SmallObjectLoader

  test "SmallObjectLoader" do
    act = :crypto.strong_rand_bytes(512) |> :binary.bin_to_list()
    loader = %SmallObjectLoader{type: Constants.obj_blob(), data: act}

    assert ObjectLoader.type(loader) == Constants.obj_blob()
    assert ObjectLoader.size(loader) == 512
    refute ObjectLoader.large?(loader)
    assert ObjectLoader.cached_bytes(loader) == act
    assert ObjectLoader.stream(loader) == act
  end
end
