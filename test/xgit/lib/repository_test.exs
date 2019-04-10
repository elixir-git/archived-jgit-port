defmodule Xgit.Lib.RepositoryTest do
  use ExUnit.Case, async: true

  alias Xgit.Errors.NoWorkTreeError
  alias Xgit.Lib.Repository

  import ExUnit.CaptureLog

  doctest Xgit.Lib.Repository

  test "handles unexpected calls" do
    pid = __MODULE__.BogusRepository.start_link!()
    assert is_pid(pid)

    assert capture_log(fn ->
             assert {:error, :unknown_message} = GenServer.call(pid, :bogus)
           end) =~ "[warn]  Repository received unrecognized call :bogus"

    assert Process.alive?(pid)
  end

  test "raises NoWorkTreeError for index_file!/1 call" do
    pid = __MODULE__.BogusRepository.start_link!()
    assert is_pid(pid)

    assert_raise NoWorkTreeError, "Bare Repository has neither a working tree, nor an index", fn ->
      Repository.index_file!(pid)
    end
  end

  test "raises NoWorkTreeError for object_database!/1 call" do
    pid = __MODULE__.BogusRepository.start_link!()
    assert is_pid(pid)

    assert_raise NoWorkTreeError, "Bare Repository has neither a working tree, nor an index", fn ->
      Repository.object_database!(pid)
    end
  end

  defmodule BogusRepository do
    @moduledoc false

    use Xgit.Lib.Repository

    def start_link!, do: Repository.start_link!(__MODULE__, nil, [])
    def init(_), do: {:ok, nil}
  end
end
