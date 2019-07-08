defmodule Xgit.Lib.ObjectInserter do
  @moduledoc ~S"""
  Inserts objects into an existing `ObjectDatabase`.

  _PORTING NOTE:_ Not sure about the following claims:

  * An inserter is not thread-safe. Individual threads should each obtain their
    own unique inserter instance, or must arrange for locking at a higher level
    to ensure the inserter is in use by no more than one thread at a time.

  * Objects written by an inserter may not be immediately visible for reading
    after the insert method completes. Callers must invoke either
    `close` or `flush` prior to updating references or otherwise making the
    returned ObjectIds visible to other code.
  """
  use GenServer

  alias Xgit.Lib.Constants
  alias Xgit.Lib.ObjectId

  @type t :: pid

  @doc """
  Starts an `ObjectInserter` process linked to the current process.

  ## Parameters

  `module` is the name of a module that implements the callbacks defined in this module.

  `init_arg` is passed to the `init/1` function of `module`.

  `options` are passed to `GenServer.start_link/3`.

  ## Return Value

  See `GenServer.start_link/3`.
  """
  @spec start_link(module :: module, init_arg :: term, GenServer.options()) ::
          GenServer.on_start()
  def start_link(module, init_arg, options) when is_atom(module) and is_list(options),
    do: GenServer.start_link(__MODULE__, {module, init_arg}, options)

  @impl true
  def init({mod, mod_init_arg}) do
    case mod.init(mod_init_arg) do
      {:ok, state} -> {:ok, {mod, state}}
      {:stop, reason} -> {:stop, reason}
    end
  end

  @doc ~S"""
  Returns `true` if the argument is a PID representing a valid `ObjectDatabase` process.
  """
  @spec valid?(inserter :: term) :: boolean
  def valid?(inserter) when is_pid(inserter) do
    Process.alive?(inserter) &&
      GenServer.call(inserter, :valid_object_inserter?) == :valid_object_inserter
  end

  def valid?(_), do: false

  # /** Temporary working buffer for streaming data through. */
  # private byte[] tempBuffer;

  # /**
  #  * Obtain a temporary buffer for use by the ObjectInserter or its subclass.
  #  * <p>
  #  * This buffer is supplied by the ObjectInserter base class to itself and
  #  * its subclasses for the purposes of pulling data from a supplied
  #  * InputStream, passing it through a Deflater, or formatting the canonical
  #  * format of a small object like a small tree or commit.
  #  * <p>
  #  * <strong>This buffer IS NOT for translation such as auto-CRLF or content
  #  * filtering and must not be used for such purposes.</strong>
  #  * <p>
  #  * The returned buffer is small, around a few KiBs, and the size may change
  #  * between versions of JGit. Callers using this buffer must always check the
  #  * length of the returned array to ascertain how much space was provided.
  #  * <p>
  #  * There is a single buffer for each ObjectInserter, repeated calls to this
  #  * method will (usually) always return the same buffer. If the caller needs
  #  * more than one buffer, or needs a buffer of a larger size, it must manage
  #  * that buffer on its own.
  #  * <p>
  #  * The buffer is usually on first demand for a buffer.
  #  *
  #  * @return a temporary byte array for use by the caller.
  #  */
  # protected byte[] buffer() {
  #   byte[] b = tempBuffer;
  #   if (b == null)
  #     tempBuffer = b = new byte[8192];
  #   return b;
  # }

  @doc ~S"""
  Compute the name of an object, without inserting it.

  `obj_type` is the type of the object. Must be one of the `obj_*()` values from
  `Xgit.Lib.Constants`.
  """
  @spec id_for(obj_type :: Constants.obj_type(), data :: [byte]) :: ObjectId.t()
  defdelegate id_for(obj_type, data), to: ObjectId

  # /**
  #  * Compute the ObjectId for the given tree without inserting it.
  #  *
  #  * @param formatter
  #  *            a {@link org.eclipse.jgit.lib.TreeFormatter} object.
  #  * @return the computed ObjectId
  #  */
  # public ObjectId idFor(TreeFormatter formatter) {
  #   return formatter.computeId(this);
  # }
  #
  # /**
  #  * Insert a single tree into the store, returning its unique name.
  #  *
  #  * @param formatter
  #  *            the formatter containing the proposed tree's data.
  #  * @return the name of the tree object.
  #  * @throws java.io.IOException
  #  *             the object could not be stored.
  #  */
  # public final ObjectId insert(TreeFormatter formatter) throws IOException {
  #   // Delegate to the formatter, as then it can pass the raw internal
  #   // buffer back to this inserter, avoiding unnecessary data copying.
  #   //
  #   return formatter.insertTo(this);
  # }
  #
  # /**
  #  * Insert a single commit into the store, returning its unique name.
  #  *
  #  * @param builder
  #  *            the builder containing the proposed commit's data.
  #  * @return the name of the commit object.
  #  * @throws java.io.IOException
  #  *             the object could not be stored.
  #  */
  # public final ObjectId insert(CommitBuilder builder) throws IOException {
  #   return insert(Constants.OBJ_COMMIT, builder.build());
  # }
  #
  # /**
  #  * Insert a single annotated tag into the store, returning its unique name.
  #  *
  #  * @param builder
  #  *            the builder containing the proposed tag's data.
  #  * @return the name of the tag object.
  #  * @throws java.io.IOException
  #  *             the object could not be stored.
  #  */
  # public final ObjectId insert(TagBuilder builder) throws IOException {
  #   return insert(Constants.OBJ_TAG, builder.build());
  # }

  @doc ~S"""
  Insert a single object into the store, returning its unique name.

  ## Parameters

  `type` is the type code of the object to store. Must be one of the `obj_*`
  constants from `Xgit.Lib.Constants`.

  `data` is a byte list with the complete content of the object.

  ## Return Value

  Returns the object ID that waas assigned for the object.
  """
  @spec insert!(inserter :: t, type :: Constants.obj_type(), data :: [byte]) :: ObjectId.t()
  def insert!(inserter, type, data) when is_pid(inserter) and is_integer(type) and is_list(data),
    do: GenServer.call(inserter, {:insert, type, data})

  @doc ~S"""
  Invoked when `insert!/3` is called on this inserter.

  ## Return Value

  `{:ok, object_id, state}` where `object_id` is the object ID that waas assigned
  for the object.
  """
  @callback handle_insert(state :: term, type :: Constants.obj_type(), data :: [byte]) ::
              {:ok, object_id :: ObjectID.t(), state :: term}

  # /**
  #  * Initialize a parser to read from a pack formatted stream.
  #  *
  #  * @param in
  #  *            the input stream. The stream is not closed by the parser, and
  #  *            must instead be closed by the caller once parsing is complete.
  #  * @return the pack parser.
  #  * @throws java.io.IOException
  #  *             the parser instance, which can be configured and then used to
  #  *             parse objects into the ObjectDatabase.
  #  */
  # public abstract PackParser newPackParser(InputStream in) throws IOException;
  #
  # /**
  #  * Open a reader for objects that may have been written by this inserter.
  #  * <p>
  #  * The returned reader allows the calling thread to read back recently
  #  * inserted objects without first calling {@code flush()} to make them
  #  * visible to the repository. The returned reader should only be used from
  #  * the same thread as the inserter. Objects written by this inserter may not
  #  * be visible to {@code this.newReader().newReader()}.
  #  * <p>
  #  * The returned reader should return this inserter instance from {@link
  #  * ObjectReader#getCreatedFromInserter()}.
  #  * <p>
  #  * Behavior is undefined if an insert method is called on the inserter in the
  #  * middle of reading from an {@link ObjectStream} opened from this reader. For
  #  * example, reading the remainder of the object may fail, or newly written
  #  * data may even be corrupted. Interleaving whole object reads (including
  #  * streaming reads) with inserts is fine, just not interleaving streaming
  #  * <em>partial</em> object reads with inserts.
  #  *
  #  * @since 3.5
  #  * @return reader for any object, including an object recently inserted by
  #  *         this inserter since the last flush.
  #  */
  # public abstract ObjectReader newReader();

  ## TODO: Port this first.

  @doc ~S"""
  Make all inserted objects visible.

  The flush may take some period of time to make the objects available to
  other processes.

  ## Return Value

  `{:ok}`

  ## Errors

  May raise `File.Error` or similar if the flush could not be completed. If this
  occurs, objects inserted thus far are in an indeterminate state.
  """
  @spec flush!(inserter :: t) :: :ok
  def flush!(inserter) when is_pid(inserter), do: GenServer.call(inserter, :flush)

  @doc ~S"""
  Invoked when `flush!/1` is called on this inserter.

  ## Return Value

  `{:ok, state}`.
  """
  @callback handle_flush(state :: term) :: {:ok, state :: term}

  # /**
  #  * {@inheritDoc}
  #  * <p>
  #  * Release any resources used by this inserter.
  #  * <p>
  #  * An inserter that has been released can be used again, but may need to be
  #  * released after the subsequent usage.
  #  *
  #  * @since 4.0
  #  */
  # @Override
  # public abstract void close();

  @impl true
  def handle_call(:valid_object_inserter?, _from, state),
    do: {:reply, :valid_object_inserter, state}

  def handle_call({:insert, type, data}, _from, {mod, mod_state}) do
    {:ok, object_id, mod_state} = mod.handle_insert(mod_state, type, data)
    {:reply, object_id, {mod, mod_state}}
  end

  def handle_call(:flush, _from, {mod, mod_state}) do
    :ok = mod.handle_flush(mod_state)
    {:reply, :ok, {mod, mod_state}}
  end

  def handle_call(message, from, {mod, mod_state}) do
    {:reply, dir, mod_state} = mod.handle_extra_call(message, from, mod_state)
    {:reply, dir, {mod, mod_state}}
  end

  @doc ~S"""
  Respond to any messages that may not be handled by `ObjectInserter`'s
  `handle_call/3` function.

  See `c:GenServer.handle_call/3`.
  """
  @callback handle_extra_call(message :: term, from :: pid, state :: term) ::
              {:reply, reply, new_state}
              | {:reply, reply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:stop, reason, reply, new_state}
              | {:stop, reason, new_state}
            when reply: term(), new_state: term(), reason: term()

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer, opts

      alias Xgit.Lib.ObjectInserter

      require Logger

      @behaviour Xgit.Lib.ObjectInserter

      @impl true
      def handle_extra_call(message, _from, state) do
        Logger.warn("ObjectInserter received unrecognized call #{inspect(message)}")
        {:reply, {:error, :unknown_message}, state}
      end

      defoverridable handle_extra_call: 3
    end
  end

  # PORTING NOTE: The jgit embedded class Formatter is not ported in Xgit as its
  # only purpose was to provide what is essentially a static function `idFor`.
  # In Xgit, this is available as a plain function in the `ObjectInserter` module
  # so there is no need for a separate `Formatter` module.
end
