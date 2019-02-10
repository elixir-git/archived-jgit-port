defmodule Xgit.Util.RawParseUtils do
  @moduledoc ~S"""
  Handy utility functions to parse raw object contents.
  """

  alias Xgit.Errors.UnsupportedCharsetError

  # /**
  #  * Determine if b[ptr] matches src.
  #  *
  #  * @param b
  #  *            the buffer to scan.
  #  * @param ptr
  #  *            first position within b, this should match src[0].
  #  * @param src
  #  *            the buffer to test for equality with b.
  #  * @return ptr + src.length if b[ptr..src.length] == src; else -1.
  #  */
  # public static final int match(byte[] b, int ptr, byte[] src) {
  # 	if (ptr + src.length > b.length)
  # 		return -1;
  # 	for (int i = 0; i < src.length; i++, ptr++)
  # 		if (b[ptr] != src[i])
  # 			return -1;
  # 	return ptr;
  # }

  # /**
  #  * Format a base 10 numeric into a temporary buffer.
  #  * <p>
  #  * Formatting is performed backwards. The method starts at offset
  #  * <code>o-1</code> and ends at <code>o-1-digits</code>, where
  #  * <code>digits</code> is the number of positions necessary to store the
  #  * base 10 value.
  #  * <p>
  #  * The argument and return values from this method make it easy to chain
  #  * writing, for example:
  #  * </p>
  #  *
  #  * <pre>
  #  * final byte[] tmp = new byte[64];
  #  * int ptr = tmp.length;
  #  * tmp[--ptr] = '\n';
  #  * ptr = RawParseUtils.formatBase10(tmp, ptr, 32);
  #  * tmp[--ptr] = ' ';
  #  * ptr = RawParseUtils.formatBase10(tmp, ptr, 18);
  #  * tmp[--ptr] = 0;
  #  * final String str = new String(tmp, ptr, tmp.length - ptr);
  #  * </pre>
  #  *
  #  * @param b
  #  *            buffer to write into.
  #  * @param o
  #  *            one offset past the location where writing will begin; writing
  #  *            proceeds towards lower index values.
  #  * @param value
  #  *            the value to store.
  #  * @return the new offset value <code>o</code>. This is the position of
  #  *         the last byte written. Additional writing should start at one
  #  *         position earlier.
  #  */
  # public static int formatBase10(final byte[] b, int o, int value) {
  # 	if (value == 0) {
  # 		b[--o] = '0';
  # 		return o;
  # 	}
  # 	final boolean isneg = value < 0;
  # 	if (isneg)
  # 		value = -value;
  # 	while (value != 0) {
  # 		b[--o] = base10byte[value % 10];
  # 		value /= 10;
  # 	}
  # 	if (isneg)
  # 		b[--o] = '-';
  # 	return o;
  # }

  @doc ~S"""
  Parse a base 10 numeric from a charlist of ASCII digits into a number.

  Digit sequences can begin with an optional run of spaces before the
  sequence, and may start with a `+` or a `-` to indicate sign position.
  Any other characters will cause the method to stop and return the current
  result to the caller.

  Returns `{number, new_buffer}` where `number` is the integer that was
  found (or 0 if no number found there) and `new_buffer` is the charlist
  following the number that was parsed.

  Similar to `Integer.parse/2` but uses charlist instead.
  """
  def parse_base_10(b) when is_list(b) do
    b = skip_white_space(b)
    {sign, b} = parse_sign(b)
    {n, b} = parse_digits(0, b)

    {sign * n, b}
  end

  defp skip_white_space([?\s | b]), do: skip_white_space(b)
  defp skip_white_space(b), do: b

  defp parse_sign([?- | b]), do: {-1, b}
  defp parse_sign([?+ | b]), do: {1, b}
  defp parse_sign(b), do: {1, b}

  defp parse_digits(n, [d | b]) when d >= ?0 and d <= ?9, do: parse_digits(n * 10 + (d - ?0), b)
  defp parse_digits(n, b), do: {n, b}

  @doc ~S"""
  Parse 4 character base 16 (hex) formatted string to integer.

  The number is read in network byte order, that is, most significant
  nybble first.

  Returns `{number, new_buffer}` where `number` is the integer that was
  found (or 0 if no number found there) and `new_buffer` is the charlist
  following the number that was parsed.
  """
  def parse_hex_int16(b) when is_list(b), do: parse_hex_digits(b, 0, 4)

  @doc ~S"""
  Parse 8 character base 16 (hex) formatted string to integer.

  The number is read in network byte order, that is, most significant
  nybble first.

  Returns `{number, new_buffer}` where `number` is the integer that was
  found (or 0 if no number found there) and `new_buffer` is the charlist
  following the number that was parsed.
  """
  def parse_hex_int32(b) when is_list(b), do: parse_hex_digits(b, 0, 8)

  @doc ~S"""
  Parse 16 character base 16 (hex) formatted string to integer.

  The number is read in network byte order, that is, most significant
  nybble first.

  Returns `{number, new_buffer}` where `number` is the integer that was
  found (or 0 if no number found there) and `new_buffer` is the charlist
  following the number that was parsed.
  """
  def parse_hex_int64(b) when is_list(b), do: parse_hex_digits(b, 0, 16)

  @doc ~S"""
  Parse a single hex digitto unsigned integer.

  The number is read in network byte order, that is, most significant
  nybble first.

  Returns `{number, new_buffer}` where `number` is the integer that was
  found (or 0 if no number found there) and `new_buffer` is the charlist
  following the number that was parsed.
  """
  def parse_hex_int4(b) when is_list(b), do: parse_hex_digits(b, 0, 1)

  defp parse_hex_digits(b, n, 0), do: {n, b}

  defp parse_hex_digits([d | b], n, rem) when d >= ?0 and d <= ?9,
    do: parse_hex_digits(b, n * 16 + (d - ?0), rem - 1)

  defp parse_hex_digits([d | b], n, rem) when d >= ?A and d <= ?F,
    do: parse_hex_digits(b, n * 16 + (d - ?A + 10), rem - 1)

  defp parse_hex_digits([d | b], n, rem) when d >= ?a and d <= ?f,
    do: parse_hex_digits(b, n * 16 + (d - ?a + 10), rem - 1)

  @doc ~S"""
  Parse a Git style timezone string.

  The sequence `-0315` will be parsed as the numeric value -195, as the
  lower two positions count minutes, not 100ths of an hour.

  Returns `{number, new_buffer}` where `number` is the time zone offset in minutes
  that was found (or 0 if no number found there) and `new_buffer` is the charlist
  following the number that was parsed.
  """
  def parse_timezone_offset(b) when is_list(b) do
    {v, b} = parse_base_10(b)

    tz_min = rem(v, 100)
    tz_hour = div(v, 100)

    {tz_hour * 60 + tz_min, b}
  end

  @doc ~S"""
  Locate the first position after a given character.
  """
  def next([char | b], char) when is_integer(char), do: b
  def next([_ | b], char) when is_integer(char), do: next(b, char)
  def next([], char) when is_integer(char), do: []

  @doc ~S"""
  Locate the first position after the next LF.

  This method stops on the first '\n' it finds.
  """
  def next_lf(b), do: next(b, ?\n)

  @doc ~S"""
  Locate the first position after either the given character or LF.

  This method stops on the first match it finds from either `char` or `\n`.
  """
  def next_lf([char | b], char) when is_integer(char), do: b
  def next_lf([?\n | b], char) when is_integer(char), do: b
  def next_lf([_ | b], char) when is_integer(char), do: next_lf(b, char)
  def next_lf([], char) when is_integer(char), do: []

  @doc ~S"""
  Return the contents of the charlist up to, but not including, the next LF.
  """
  def until_next_lf(b), do: Enum.take_while(b, fn c -> c != ?\n end)

  @doc ~S"""
  Return the contents of the charlist up to, but not including, the next instance
  of the given character or LF.
  """
  def until_next_lf(b, char), do: Enum.take_while(b, fn c -> c != ?\n and c != char end)

  @doc ~S"""
  Locate the end of the header. Note that headers may be more than one line long.

  Returns charlist beginning just after the header. This is either `[]` or the
  charlist beginning with the `\n` character that terminates the header.
  """
  def header_end([?\n | [?\s | b]]), do: header_end(b)
  def header_end([?\n | _] = b), do: b
  def header_end([]), do: []
  def header_end([_ | b]), do: header_end(b)

  @doc ~S"""
  Find the start of the contents of a given header in the given charlist.

  Returns charlist beginning at the start of the header's contents or `nil`
  if not found.

  *IMPORTANT:* Unlike the git version of this function, it does not advance
  to the beginning of the next line. Because the API speaks in charlists, we cannot
  differentiate between the beginning of the initial string buffer and a subsequent
  internal portion of the buffer. Clients may need to add their own call to `next_lf/1`
  where it would not have been necessary in git.
  """
  def header_start([_ | _] = header_name, b) when is_list(b),
    do: possible_header_match(header_name, header_name, b, b)

  def possible_header_match(header_name, [c | rest_of_header], match_start, [c | rest_of_match]),
    do: possible_header_match(header_name, rest_of_header, match_start, rest_of_match)

  def possible_header_match(_header_name, [], _match_start, [?\s | header_content]),
    do: header_content

  def possible_header_match(_header_name, _, [], _), do: nil

  def possible_header_match(header_name, _, [_ | b], _),
    do: possible_header_match(header_name, header_name, b, b)

  # Holding off on implementing prev and prev_lf. These are not feasible with the
  # current design using charlists.

  # /**
  # * Locate the first position before a given character.
  # *
  # * @param b
  # *            buffer to scan.
  # * @param ptr
  # *            position within buffer to start looking for chrA at.
  # * @param chrA
  # *            character to find.
  # * @return new position just before chrA, -1 for not found
  # */
  # public static final int prev(byte[] b, int ptr, char chrA) {
  # if (ptr == b.length)
  # --ptr;
  # while (ptr >= 0) {
  # if (b[ptr--] == chrA)
  # return ptr;
  # }
  # return ptr;
  # }

  # /**
  # * Locate the first position before the previous LF.
  # * <p>
  # * This method stops on the first '\n' it finds.
  # *
  # * @param b
  # *            buffer to scan.
  # * @param ptr
  # *            position within buffer to start looking for LF at.
  # * @return new position just before the first LF found, -1 for not found
  # */
  # public static final int prevLF(byte[] b, int ptr) {
  # return prev(b, ptr, '\n');
  # }
  #
  # /**
  # * Locate the previous position before either the given character or LF.
  # * <p>
  # * This method stops on the first match it finds from either chrA or '\n'.
  # *
  # * @param b
  # *            buffer to scan.
  # * @param ptr
  # *            position within buffer to start looking for chrA or LF at.
  # * @param chrA
  # *            character to find.
  # * @return new position just before the first chrA or LF to be found, -1 for
  # *         not found
  # */
  # public static final int prevLF(byte[] b, int ptr, char chrA) {
  # if (ptr == b.length)
  # --ptr;
  # while (ptr >= 0) {
  # final byte c = b[ptr--];
  # if (c == chrA || c == '\n')
  # return ptr;
  # }
  # return ptr;
  # }

  @doc ~S"""
  Locate the `author ` header line data.

  Returns a charlist beginning just after the space in `author ` which should be
  the first character of the author's name. If no author header can be located,
  `nil` is returned.
  """
  def author(b) when is_list(b), do: header_start('author', b)

  @doc ~S"""
  Locate the `committer ` header line data.

  Returns a charlist beginning just after the space in `committer ` which should be
  the first character of the committer's name. If no committer header can be located,
  `nil` is returned.
  """
  def committer(b) when is_list(b), do: header_start('committer', b)

  @doc ~S"""
  Locate the `tagger ` header line data.

  Returns a charlist beginning just after the space in `tagger ` which should be
  the first character of the tagger's name. If no tagger header can be located,
  `nil` is returned.
  """
  def tagger(b) when is_list(b), do: header_start('tagger', b)

  @doc ~S"""
  Locate the `encoding ` header line data.

  Returns a charlist beginning just after the space in `encoding ` which should be
  the first character of the encoding's name. If no encoding header can be located,
  `nil` is returned (ad UTF-8 should be assumed).
  """
  def encoding(b) when is_list(b), do: header_start('encoding', b)

  @doc ~S"""
  Parse the `encoding ` header as a string.

  Returns the encoding header as specified in the commit or `nil` if the header
  was not present and should be assumed.
  """
  def parse_encoding_name(b) when is_list(b) do
    enc = encoding(b)

    if enc == nil do
      nil
    else
      enc
      |> until_next_lf()
      |> decode()
    end
  end

  @doc ~S"""
  Parse the `encoding ` header into a character set reference.

  Returns `:utf8` or `:latin`.

  Raises `UnsupportedCharsetError` if the character set is unknown.
  WARNING: Compared to jgit, the character set support in xgit is limited.
  """
  def parse_encoding(b) when is_list(b) do
    case b |> parse_encoding_name() |> trim_if_string() do
      nil -> :utf8
      "UTF-8" -> :utf8
      "ISO-8859-1" -> :latin1
      x -> raise UnsupportedCharsetError, charset: x
    end
  end

  defp trim_if_string(s) when is_binary(s), do: String.trim(s)
  defp trim_if_string(s), do: s

  # /**
  # * Parse a name string (e.g. author, committer, tagger) into a PersonIdent.
  # * <p>
  # * Leading spaces won't be trimmed from the string, i.e. will show up in the
  # * parsed name afterwards.
  # *
  # * @param in
  # *            the string to parse a name from.
  # * @return the parsed identity or null in case the identity could not be
  # *         parsed.
  # */
  # public static PersonIdent parsePersonIdent(String in) {
  # return parsePersonIdent(Constants.encode(in), 0);
  # }
  #
  # /**
  # * Parse a name line (e.g. author, committer, tagger) into a PersonIdent.
  # * <p>
  # * When passing in a value for <code>nameB</code> callers should use the
  # * return value of {@link #author(byte[], int)} or
  # * {@link #committer(byte[], int)}, as these methods provide the proper
  # * position within the buffer.
  # *
  # * @param raw
  # *            the buffer to parse character data from.
  # * @param nameB
  # *            first position of the identity information. This should be the
  # *            first position after the space which delimits the header field
  # *            name (e.g. "author" or "committer") from the rest of the
  # *            identity line.
  # * @return the parsed identity or null in case the identity could not be
  # *         parsed.
  # */
  # public static PersonIdent parsePersonIdent(byte[] raw, int nameB) {
  # Charset cs;
  # try {
  # cs = parseEncoding(raw);
  # } catch (IllegalCharsetNameException | UnsupportedCharsetException e) {
  # // Assume UTF-8 for person identities, usually this is correct.
  # // If not decode() will fall back to the ISO-8859-1 encoding.
  # cs = UTF_8;
  # }
  #
  # final int emailB = nextLF(raw, nameB, '<');
  # final int emailE = nextLF(raw, emailB, '>');
  # if (emailB >= raw.length || raw[emailB] == '\n' ||
  # (emailE >= raw.length - 1 && raw[emailE - 1] != '>'))
  # return null;
  #
  # final int nameEnd = emailB - 2 >= nameB && raw[emailB - 2] == ' ' ?
  # emailB - 2 : emailB - 1;
  # final String name = decode(cs, raw, nameB, nameEnd);
  # final String email = decode(cs, raw, emailB, emailE - 1);
  #
  # // Start searching from end of line, as after first name-email pair,
  # // another name-email pair may occur. We will ignore all kinds of
  # // "junk" following the first email.
  # //
  # // We've to use (emailE - 1) for the case that raw[email] is LF,
  # // otherwise we would run too far. "-2" is necessary to position
  # // before the LF in case of LF termination resp. the penultimate
  # // character if there is no trailing LF.
  # final int tzBegin = lastIndexOfTrim(raw, ' ',
  # nextLF(raw, emailE - 1) - 2) + 1;
  # if (tzBegin <= emailE) // No time/zone, still valid
  # return new PersonIdent(name, email, 0, 0);
  #
  # final int whenBegin = Math.max(emailE,
  # lastIndexOfTrim(raw, ' ', tzBegin - 1) + 1);
  # if (whenBegin >= tzBegin - 1) // No time/zone, still valid
  # return new PersonIdent(name, email, 0, 0);
  #
  # final long when = parseLongBase10(raw, whenBegin, null);
  # final int tz = parseTimeZoneOffset(raw, tzBegin);
  # return new PersonIdent(name, email, when * 1000L, tz);
  # }
  #
  # /**
  # * Parse a name data (e.g. as within a reflog) into a PersonIdent.
  # * <p>
  # * When passing in a value for <code>nameB</code> callers should use the
  # * return value of {@link #author(byte[], int)} or
  # * {@link #committer(byte[], int)}, as these methods provide the proper
  # * position within the buffer.
  # *
  # * @param raw
  # *            the buffer to parse character data from.
  # * @param nameB
  # *            first position of the identity information. This should be the
  # *            first position after the space which delimits the header field
  # *            name (e.g. "author" or "committer") from the rest of the
  # *            identity line.
  # * @return the parsed identity. Never null.
  # */
  # public static PersonIdent parsePersonIdentOnly(final byte[] raw,
  # final int nameB) {
  # int stop = nextLF(raw, nameB);
  # int emailB = nextLF(raw, nameB, '<');
  # int emailE = nextLF(raw, emailB, '>');
  # final String name;
  # final String email;
  # if (emailE < stop) {
  # email = decode(raw, emailB, emailE - 1);
  # } else {
  # email = "invalid"; //$NON-NLS-1$
  # }
  # if (emailB < stop)
  # name = decode(raw, nameB, emailB - 2);
  # else
  # name = decode(raw, nameB, stop);
  #
  # final MutableInteger ptrout = new MutableInteger();
  # long when;
  # int tz;
  # if (emailE < stop) {
  # when = parseLongBase10(raw, emailE + 1, ptrout);
  # tz = parseTimeZoneOffset(raw, ptrout.value);
  # } else {
  # when = 0;
  # tz = 0;
  # }
  # return new PersonIdent(name, email, when * 1000L, tz);
  # }
  #
  # /**
  # * Locate the end of a footer line key string.
  # * <p>
  # * If the region at {@code raw[ptr]} matches {@code ^[A-Za-z0-9-]+:} (e.g.
  # * "Signed-off-by: A. U. Thor\n") then this method returns the position of
  # * the first ':'.
  # * <p>
  # * If the region at {@code raw[ptr]} does not match {@code ^[A-Za-z0-9-]+:}
  # * then this method returns -1.
  # *
  # * @param raw
  # *            buffer to scan.
  # * @param ptr
  # *            first position within raw to consider as a footer line key.
  # * @return position of the ':' which terminates the footer line key if this
  # *         is otherwise a valid footer line key; otherwise -1.
  # */
  # public static int endOfFooterLineKey(byte[] raw, int ptr) {
  # try {
  # for (;;) {
  # final byte c = raw[ptr];
  # if (footerLineKeyChars[c] == 0) {
  # if (c == ':')
  # return ptr;
  # return -1;
  # }
  # ptr++;
  # }
  # } catch (ArrayIndexOutOfBoundsException e) {
  # return -1;
  # }
  # }

  @doc ~S"""
  Convert a list of bytes to an Elixir (UTF-8) string when the encoding is not
  definitively know. Try parsing as a UTF-8 byte array first, then try ISO-8859-1.

  PORTING NOTE: A lot of the simplification of this compared to jgit's implementation
  of RawParseUtils.decode comes from the observation that the only character set
  ever passed to jgit's decode was UTF-8. We've baked that assumption into this
  implementation. Should other character sets come into play, this will necessarily
  become more complicated.
  """
  def decode(b) when is_list(b) do
    raw = :erlang.list_to_binary(b)

    case :unicode.characters_to_binary(raw) do
      utf8 when is_binary(utf8) -> utf8
      _ -> :unicode.characters_to_binary(raw, :latin1)
    end
  end

  @doc ~S"""
  Convert a list of bytes from ISO-8859-1 to an Elixir (UTF-8) string.

  TO DO: Remove this in favor of to_string/1 when the one external
  reference (in FileHeader) is ported.
  """
  def extract_binary_string(b) when is_list(b), do: to_string(b)

  # /**
  # * Locate the position of the commit message body.
  # *
  # * @param b
  # *            buffer to scan.
  # * @param ptr
  # *            position in buffer to start the scan at. Most callers should
  # *            pass 0 to ensure the scan starts from the beginning of the
  # *            commit buffer.
  # * @return position of the user's message buffer.
  # */
  # public static final int commitMessage(byte[] b, int ptr) {
  # final int sz = b.length;
  # if (ptr == 0)
  # ptr += 46; // skip the "tree ..." line.
  # while (ptr < sz && b[ptr] == 'p')
  # ptr += 48; // skip this parent.
  #
  # // Skip any remaining header lines, ignoring what their actual
  # // header line type is. This is identical to the logic for a tag.
  # //
  # return tagMessage(b, ptr);
  # }
  #
  # /**
  # * Locate the position of the tag message body.
  # *
  # * @param b
  # *            buffer to scan.
  # * @param ptr
  # *            position in buffer to start the scan at. Most callers should
  # *            pass 0 to ensure the scan starts from the beginning of the tag
  # *            buffer.
  # * @return position of the user's message buffer.
  # */
  # public static final int tagMessage(byte[] b, int ptr) {
  # final int sz = b.length;
  # if (ptr == 0)
  # ptr += 48; // skip the "object ..." line.
  # while (ptr < sz && b[ptr] != '\n')
  # ptr = nextLF(b, ptr);
  # if (ptr < sz && b[ptr] == '\n')
  # return ptr + 1;
  # return -1;
  # }

  @doc ~S"""
  Return the contents of the charlist up to, but not including, the next end-of-paragraph
  sequence.
  """
  def until_end_of_paragraph(b) when is_list(b),
    do: until_end_of_paragraph([], b)

  defp until_end_of_paragraph(acc, [?\r | [?\n | [?\r | _]]]), do: acc
  defp until_end_of_paragraph(acc, [?\n | [?\n | _]]), do: acc
  defp until_end_of_paragraph(acc, [c | rem]), do: until_end_of_paragraph(acc ++ [c], rem)
  defp until_end_of_paragraph(acc, []), do: acc

  @doc ~S"""
  Return the portion of the byte array up to, but not including the last instance of
  `ch`, disregarding any trailing spaces.
  """
  def until_last_instance_of_trim(b, ch) when is_list(b) do
    b
    |> Enum.reverse()
    |> Enum.drop_while(&(&1 == ?\s))
    |> Enum.drop_while(&(&1 != ch))
    |> Enum.drop(1)
    |> Enum.reverse()
  end
end
