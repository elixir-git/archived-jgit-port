# Copyright (C) 2008, 2015 Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/util/NB.java
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

defmodule Xgit.Util.NB do
  @moduledoc ~S"""
  Conversion utilities for network byte order handling.
  """

  # /**
  #  * Compare a 32 bit unsigned integer stored in a 32 bit signed integer.
  #  * <p>
  #  * This function performs an unsigned compare operation, even though Java
  #  * does not natively support unsigned integer values. Negative numbers are
  #  * treated as larger than positive ones.
  #  *
  #  * @param a
  #  *            the first value to compare.
  #  * @param b
  #  *            the second value to compare.
  #  * @return &lt; 0 if a &lt; b; 0 if a == b; &gt; 0 if a &gt; b.
  #  */
  # public static int compareUInt32(final int a, final int b) {
  #   final int cmp = (a >>> 1) - (b >>> 1);
  #   if (cmp != 0)
  #     return cmp;
  #   return (a & 1) - (b & 1);
  # }
  #
  # /**
  #  * Compare a 64 bit unsigned integer stored in a 64 bit signed integer.
  #  * <p>
  #  * This function performs an unsigned compare operation, even though Java
  #  * does not natively support unsigned integer values. Negative numbers are
  #  * treated as larger than positive ones.
  #  *
  #  * @param a
  #  *            the first value to compare.
  #  * @param b
  #  *            the second value to compare.
  #  * @return &lt; 0 if a &lt; b; 0 if a == b; &gt; 0 if a &gt; b.
  #  * @since 4.3
  #  */
  # public static int compareUInt64(final long a, final long b) {
  #   long cmp = (a >>> 1) - (b >>> 1);
  #   if (cmp > 0) {
  #     return 1;
  #   } else if (cmp < 0) {
  #     return -1;
  #   }
  #   cmp = ((a & 1) - (b & 1));
  #   if (cmp > 0) {
  #     return 1;
  #   } else if (cmp < 0) {
  #     return -1;
  #   } else {
  #     return 0;
  #   }
  # }
  #
  # /**
  #  * Convert sequence of 2 bytes (network byte order) into unsigned value.
  #  *
  #  * @param intbuf
  #  *            buffer to acquire the 2 bytes of data from.
  #  * @param offset
  #  *            position within the buffer to begin reading from. This
  #  *            position and the next byte after it (for a total of 2 bytes)
  #  *            will be read.
  #  * @return unsigned integer value that matches the 16 bits read.
  #  */
  # public static int decodeUInt16(final byte[] intbuf, final int offset) {
  #   int r = (intbuf[offset] & 0xff) << 8;
  #   return r | (intbuf[offset + 1] & 0xff);
  # }
  #
  # /**
  #  * Convert sequence of 3 bytes (network byte order) into unsigned value.
  #  *
  #  * @param intbuf
  #  *            buffer to acquire the 3 bytes of data from.
  #  * @param offset
  #  *            position within the buffer to begin reading from. This
  #  *            position and the next 2 bytes after it (for a total of 3
  #  *            bytes) will be read.
  #  * @return signed integer value that matches the 24 bits read.
  #  * @since 4.9
  #  */
  # public static int decodeUInt24(byte[] intbuf, int offset) {
  #   int r = (intbuf[offset] & 0xff) << 8;
  #   r |= intbuf[offset + 1] & 0xff;
  #   return (r << 8) | (intbuf[offset + 2] & 0xff);
  # }

  @doc ~S"""
  Convert sequence of 4 bytes (network byte order) into signed value.

  Reads the first four bytes from `intbuf` and returns `{value, buf}`
  where value is the integer value from the first four bytes at `intbuf`
  and `buf` is the remainder of the byte array after those bytes.
  """
  def decode_int32([b1, b2, b3, b4 | tail]) when b1 >= 128,
    do: {b1 * 0x1000000 + b2 * 0x10000 + b3 * 0x100 + b4 - 0x100000000, tail}

  def decode_int32([b1, b2, b3, b4 | tail]),
    do: {b1 * 0x1000000 + b2 * 0x10000 + b3 * 0x100 + b4, tail}

  # /**
  #  * Convert sequence of 8 bytes (network byte order) into signed value.
  #  *
  #  * @param intbuf
  #  *            buffer to acquire the 8 bytes of data from.
  #  * @param offset
  #  *            position within the buffer to begin reading from. This
  #  *            position and the next 7 bytes after it (for a total of 8
  #  *            bytes) will be read.
  #  * @return signed integer value that matches the 64 bits read.
  #  * @since 3.0
  #  */
  # public static long decodeInt64(final byte[] intbuf, final int offset) {
  #   long r = intbuf[offset] << 8;
  #
  #   r |= intbuf[offset + 1] & 0xff;
  #   r <<= 8;
  #
  #   r |= intbuf[offset + 2] & 0xff;
  #   r <<= 8;
  #
  #   r |= intbuf[offset + 3] & 0xff;
  #   r <<= 8;
  #
  #   r |= intbuf[offset + 4] & 0xff;
  #   r <<= 8;
  #
  #   r |= intbuf[offset + 5] & 0xff;
  #   r <<= 8;
  #
  #   r |= intbuf[offset + 6] & 0xff;
  #   return (r << 8) | (intbuf[offset + 7] & 0xff);
  # }

  @doc ~S"""
  Convert sequence of 4 bytes (network byte order) into unsigned value.

  Reads the first four bytes from `intbuf` and returns `{value, buf}`
  where value is the unsigned integer value from the first four bytes at `intbuf`
  and `buf` is the remainder of the byte array after those bytes.
  """
  def decode_uint32([b1, b2, b3, b4 | tail]),
    do: {b1 * 0x1000000 + b2 * 0x10000 + b3 * 0x100 + b4, tail}

  # /**
  #  * Convert sequence of 8 bytes (network byte order) into unsigned value.
  #  *
  #  * @param intbuf
  #  *            buffer to acquire the 8 bytes of data from.
  #  * @param offset
  #  *            position within the buffer to begin reading from. This
  #  *            position and the next 7 bytes after it (for a total of 8
  #  *            bytes) will be read.
  #  * @return unsigned integer value that matches the 64 bits read.
  #  */
  # public static long decodeUInt64(final byte[] intbuf, final int offset) {
  #   return (decodeUInt32(intbuf, offset) << 32)
  #       | decodeUInt32(intbuf, offset + 4);
  # }
  #
  # /**
  #  * Write a 16 bit integer as a sequence of 2 bytes (network byte order).
  #  *
  #  * @param intbuf
  #  *            buffer to write the 2 bytes of data into.
  #  * @param offset
  #  *            position within the buffer to begin writing to. This position
  #  *            and the next byte after it (for a total of 2 bytes) will be
  #  *            replaced.
  #  * @param v
  #  *            the value to write.
  #  */
  # public static void encodeInt16(final byte[] intbuf, final int offset, int v) {
  #   intbuf[offset + 1] = (byte) v;
  #   v >>>= 8;
  #
  #   intbuf[offset] = (byte) v;
  # }
  #
  # /**
  #  * Write a 24 bit integer as a sequence of 3 bytes (network byte order).
  #  *
  #  * @param intbuf
  #  *            buffer to write the 3 bytes of data into.
  #  * @param offset
  #  *            position within the buffer to begin writing to. This position
  #  *            and the next 2 bytes after it (for a total of 3 bytes) will be
  #  *            replaced.
  #  * @param v
  #  *            the value to write.
  #  * @since 4.9
  #  */
  # public static void encodeInt24(byte[] intbuf, int offset, int v) {
  #   intbuf[offset + 2] = (byte) v;
  #   v >>>= 8;
  #
  #   intbuf[offset + 1] = (byte) v;
  #   v >>>= 8;
  #
  #   intbuf[offset] = (byte) v;
  # }
  #
  # /**
  #  * Write a 32 bit integer as a sequence of 4 bytes (network byte order).
  #  *
  #  * @param intbuf
  #  *            buffer to write the 4 bytes of data into.
  #  * @param offset
  #  *            position within the buffer to begin writing to. This position
  #  *            and the next 3 bytes after it (for a total of 4 bytes) will be
  #  *            replaced.
  #  * @param v
  #  *            the value to write.
  #  */
  # public static void encodeInt32(final byte[] intbuf, final int offset, int v) {
  #   intbuf[offset + 3] = (byte) v;
  #   v >>>= 8;
  #
  #   intbuf[offset + 2] = (byte) v;
  #   v >>>= 8;
  #
  #   intbuf[offset + 1] = (byte) v;
  #   v >>>= 8;
  #
  #   intbuf[offset] = (byte) v;
  # }
  #
  # /**
  #  * Write a 64 bit integer as a sequence of 8 bytes (network byte order).
  #  *
  #  * @param intbuf
  #  *            buffer to write the 8 bytes of data into.
  #  * @param offset
  #  *            position within the buffer to begin writing to. This position
  #  *            and the next 7 bytes after it (for a total of 8 bytes) will be
  #  *            replaced.
  #  * @param v
  #  *            the value to write.
  #  */
  # public static void encodeInt64(final byte[] intbuf, final int offset, long v) {
  #   intbuf[offset + 7] = (byte) v;
  #   v >>>= 8;
  #
  #   intbuf[offset + 6] = (byte) v;
  #   v >>>= 8;
  #
  #   intbuf[offset + 5] = (byte) v;
  #   v >>>= 8;
  #
  #   intbuf[offset + 4] = (byte) v;
  #   v >>>= 8;
  #
  #   intbuf[offset + 3] = (byte) v;
  #   v >>>= 8;
  #
  #   intbuf[offset + 2] = (byte) v;
  #   v >>>= 8;
  #
  #   intbuf[offset + 1] = (byte) v;
  #   v >>>= 8;
  #
  #   intbuf[offset] = (byte) v;
  # }
end
