# Copyright (C) 2007, Robin Rosenberg <robin.rosenberg@dewire.com>
# Copyright (C) 2008, Shawn O. Pearce <spearce@spearce.org>
# Copyright (C) 2009, Google Inc.
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/internal/storage/file/ObjectDirectoryInserter.java
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

defmodule Xgit.Storage.File.Internal.ObjectDirectoryInserter do
  # INTERNAL: Creates loose objects in an `ObjectDirectory`.
  use Xgit.Lib.ObjectInserter

  alias Xgit.Lib.Config
  alias Xgit.Lib.Constants
  alias Xgit.Lib.ObjectDatabase
  alias Xgit.Lib.ObjectId
  alias Xgit.Storage.File.Internal.ObjectDirectory
  alias Xgit.Storage.File.Internal.WriteConfig

  @doc """
  Starts an `ObjectDirectoryInserter` process linked to the current process.

  ## Parameters

  `module` is the name of a module that implements the callbacks defined in this module.

  `init_arg` is passed to the `init/1` function of `module`.

  `options` are passed to `GenServer.start_link/3`.

  ## Return Value

  See `GenServer.start_link/3`.
  """
  @spec start_link(
          object_database :: ObjectDatabase.t(),
          config :: Config.t(),
          GenServer.options()
        ) ::
          GenServer.on_start()
  def start_link(object_database, %Config{} = config, options \\ []) when is_pid(object_database),
    do: ObjectInserter.start_link(__MODULE__, {object_database, config}, options)

  @impl true
  def init({object_database, config}),
    do: {:ok, %{db: object_database, config: WriteConfig.from_config(config)}}

  # private Deflater deflate;

  # /** {@inheritDoc} */
  # @Override
  # public ObjectId insert(int type, byte[] data, int off, int len)
  #     throws IOException {
  #   return insert(type, data, off, len, false);
  # }

  @impl true
  def handle_insert(state, obj_type, data), do: handle_insert(state, obj_type, data, false)

  defp handle_insert(
         %{db: object_database, config: config} = state,
         obj_type,
         data,
         create_duplicate?
       ) do
    id = ObjectId.id_for(obj_type, data)

    if !create_duplicate? && ObjectDatabase.has_object?(object_database, id) do
      {:ok, id, state}
    else
      _tmp = to_temp_file!(object_database, config, obj_type, data)
      raise "UNIMPLEMENTED"
      # File tmp = toTemp(type, data, off, len);
      # return insertOneObject(tmp, id, createDuplicate);
      # {:ok, id, state}
    end
  end

  # /**
  #  * Insert a loose object into the database. If createDuplicate is true,
  #  * write the loose object even if we already have it in the loose or packed
  #  * ODB.
  #  *
  #  * @param type
  #  * @param len
  #  * @param is
  #  * @param createDuplicate
  #  * @return ObjectId
  #  * @throws IOException
  #  */
  # ObjectId insert(int type, long len, InputStream is, boolean createDuplicate)
  #     throws IOException {
  #   if (len <= buffer().length) {
  #     byte[] buf = buffer();
  #     int actLen = IO.readFully(is, buf, 0);
  #     return insert(type, buf, 0, actLen, createDuplicate);
  #
  #   } else {
  #     SHA1 md = digest();
  #     File tmp = toTemp(md, type, len, is);
  #     ObjectId id = md.toObjectId();
  #     return insertOneObject(tmp, id, createDuplicate);
  #   }
  # }
  #
  # private ObjectId insertOneObject(
  #     File tmp, ObjectId id, boolean createDuplicate)
  #     throws IOException, ObjectWritingException {
  #   switch (db.insertUnpackedObject(tmp, id, createDuplicate)) {
  #   case INSERTED:
  #   case EXISTS_PACKED:
  #   case EXISTS_LOOSE:
  #     return id;
  #
  #   case FAILURE:
  #   default:
  #     break;
  #   }
  #
  #   final File dst = db.fileFor(id);
  #   throw new ObjectWritingException(MessageFormat
  #       .format(JGitText.get().unableToCreateNewObject, dst));
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # public PackParser newPackParser(InputStream in) throws IOException {
  #   return new ObjectDirectoryPackParser(db, in);
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # public ObjectReader newReader() {
  #   return new WindowCursor(db, this);
  # }

  @impl true
  def handle_flush(state), do: {:ok, state}
  # Nothing to do here. Loose objects are already immediately visibile.

  # /** {@inheritDoc} */
  # @Override
  # public void close() {
  #   if (deflate != null) {
  #     try {
  #       deflate.end();
  #     } finally {
  #       deflate = null;
  #     }
  #   }
  # }
  #
  # @SuppressWarnings("resource" /* java 7 */)
  # private File toTemp(final SHA1 md, final int type, long len,
  #     final InputStream is) throws IOException, FileNotFoundException,
  #     Error {
  #   boolean delete = true;
  #   File tmp = newTempFile();
  #   try {
  #     FileOutputStream fOut = new FileOutputStream(tmp);
  #     try {
  #       OutputStream out = fOut;
  #       if (config.getFSyncObjectFiles())
  #         out = Channels.newOutputStream(fOut.getChannel());
  #       DeflaterOutputStream cOut = compress(out);
  #       SHA1OutputStream dOut = new SHA1OutputStream(cOut, md);
  #       writeHeader(dOut, type, len);
  #
  #       final byte[] buf = buffer();
  #       while (len > 0) {
  #         int n = is.read(buf, 0, (int) Math.min(len, buf.length));
  #         if (n <= 0)
  #           throw shortInput(len);
  #         dOut.write(buf, 0, n);
  #         len -= n;
  #       }
  #       dOut.flush();
  #       cOut.finish();
  #     } finally {
  #       if (config.getFSyncObjectFiles())
  #         fOut.getChannel().force(true);
  #       fOut.close();
  #     }
  #
  #     delete = false;
  #     return tmp;
  #   } finally {
  #     if (delete)
  #       FileUtils.delete(tmp, FileUtils.RETRY);
  #   }
  # }

  defp to_temp_file!(object_database, _config, obj_type, data) do
    deflated_data = deflated_data(obj_type, data)

    tmp_file_path = new_temp_file!(object_database)

    # if (config.getFSyncObjectFiles())
    #   out = Channels.newOutputStream(fOut.getChannel());

    File.write!(temp_file_path, deflated_data, [:binary])

    # if (config.getFSyncObjectFiles())
    #   fOut.getChannel().force(true);

    # if (delete)
    #   FileUtils.delete(tmp, FileUtils.RETRY);

    tmp_file_path
  end

  defp deflated_data(obj_type, data) do
    z = :zlib.open()
    :ok = :zlib.deflateInit(z, :default)

    b1 = :zlib.deflate(z, [header(obj_type, data) | data])
    b2 = :zlib.deflate(z, <<>>, :finish)
    :zlib.deflateEnd(z)

    [b1 | b2]
  end

  defp header(obj_type, data) do
    len = Enum.count(data)
    '#{Contants.encoded_type_string(obj_type)} #{Constants.encode_ascii(len)}\0'
  end

  defp new_temp_file!(object_database),
    do: Temp.path!(prefix: "noz", basedir: ObjectDirectory.directory(object_database))

  # DeflaterOutputStream compress(OutputStream out) {
  #   if (deflate == null)
  #     deflate = new Deflater(config.getCompression());
  #   else
  #     deflate.reset();
  #   return new DeflaterOutputStream(out, deflate, 8192);
  # }
  #
  # private static EOFException shortInput(long missing) {
  #   return new EOFException(MessageFormat.format(
  #       JGitText.get().inputDidntMatchLength, Long.valueOf(missing)));
  # }
  #
  # private static class SHA1OutputStream extends FilterOutputStream {
  #   private final SHA1 md;
  #
  #   SHA1OutputStream(OutputStream out, SHA1 md) {
  #     super(out);
  #     this.md = md;
  #   }
  #
  #   @Override
  #   public void write(int b) throws IOException {
  #     md.update((byte) b);
  #     out.write(b);
  #   }
  #
  #   @Override
  #   public void write(byte[] in, int p, int n) throws IOException {
  #     md.update(in, p, n);
  #     out.write(in, p, n);
  #   }
  # }
end
