defmodule Xgit.Errors.MissingObjectError do
  @moduledoc ~S"""
  Raised when an expected object is missing.
  """
  defexception [:message, :missing_object_id]

  alias Xgit.Lib.Constants

  def exception(object_id: object_id, type: type) when is_binary(object_id) and is_binary(type) do
    %__MODULE__{message: "Missing #{type} #{object_id}", missing_object_id: object_id}
  end

  def exception(object_id: object_id, type: type)
      when is_binary(object_id) and is_integer(type) do
    exception(object_id: object_id, type: Constants.type_string(type))
  end

  def exception(object_id: object_id, type: :any) when is_binary(object_id) do
    exception(object_id: object_id, type: "(unknown type)")
  end
end
