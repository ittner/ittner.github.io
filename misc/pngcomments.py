# -*- coding: utf-8 -*-

# PNGComments.py - Reads and saves comment chunks to PNG files
# (c) 2010 Alexandre Erwin Ittner <alexandre@ittner.com.br>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston,
# MA 02111-1307, USA.
#
#
# All the information regarding the PNG file format came from the
# spec: http://www.w3.org/TR/2003/REC-PNG-20031110/
#
#

"""
Reads and saves text chunks to PNG images. More information on the PNG
format may be found in http://www.w3.org/TR/2003/REC-PNG-20031110/
"""

import os
import struct
import zlib

_PNG_MAGIC="\x89PNG\x0d\x0a\x1a\x0a"

def _write_chunk(fp, name, data=""):
    """Write a PNG data chunk to fp."""
    fp.write(struct.pack("!I", len(data)))
    fp.write(name)
    fp.write(data)
    crc = zlib.crc32(data, zlib.crc32(name))
    fp.write(struct.pack("!i", crc))


def read_text_chunks(fname):
    """ Returns a list of lists with all text chunks found in the file
    or 'None' on error. The lists follow the format [tag, content] and
    the data is returned as unencoded byte strings. """

    fp = open(fname, "rb")
    if not fp: return None  # IO error.

    if  fp.read(len(_PNG_MAGIC)) != _PNG_MAGIC:
        fp.close()
        return None     # Bad header, not a PNG.

    txchunks = [ ]
    
    # Iterate over the chunks. Read the tEXt and ignores the others.
    # Details in http://www.w3.org/TR/2003/REC-PNG-20031110/#5DataRep
    while True:

        # Chunks headers are 8 byte long. The first 4 bytes are the length
        # and the following forur are the chunk type.

        slen = fp.read(4)
        cktype  = fp.read(4)
        if not (slen and cktype):
            fp.close()
            return None     # Something is wrong. Aborts.

        cklen = struct.unpack("!I", slen)[0]
        if cklen < 0:
            # Avoids any cleverly crafted PNGs that would put the reader
            # in an infinite loop.
            fp.close()
            return None

        # TODO: Support compressed text chunks.
        if cktype == "tEXt":
            # Uncompressed text field found.
            txt = fp.read(cklen)
            if len(txt) != cklen:
                fp.close()
                return None     # Something is wrong. Aborts.
            txchunks.append(txt.split("\0"))
        elif cktype == "IEND":
            # End of file reached. Stops.
            fp.close()
            return txchunks
        else:
            # Just ignores the other chunks data.
            fp.seek(cklen, os.SEEK_CUR)

        # Jumps the checksum. It is not a very good idea...
        fp.seek(4, os.SEEK_CUR)

    # End of file reached without and IEND. Not so good.
    fp.close()
    return txchunks


def write_text_chunks(fromfile, tofile, chunks, ignore_existing=False):
    """ Copies the PNG file in 'fromfile' to 'tofile', adding the text
    chunks given by 'chunks', a list of lists in the format
    [ [ tag, content ] ... ] where both the tag and the content are
    unencoded byte strings. If 'ignore_existing' is true, all existing
    text chunks will be discarted.   Returns True on success and False
    on failure. """

    ifp = open(fromfile, "rb")
    if not ifp: return False

    if  ifp.read(len(_PNG_MAGIC)) != _PNG_MAGIC:
        ifp.close()
        return False     # Bad header, not a PNG.

    ofp = open(tofile, "wb")
    if not ofp:
        ifp.close()
        return False

    ofp.write(_PNG_MAGIC)
    written = False

    # Iterate over the chunks, copying them
    while True:

        # Chunks headers are 8 byte long. The first 4 bytes are the length
        # and the following forur are the chunk type.

        slen = ifp.read(4)
        cktype  = ifp.read(4)
        if not (slen and cktype):
            ifp.close()
            ofp.close()
            return False     # Something is wrong. Aborts.

        cklen = struct.unpack("!I", slen)[0]
        if cklen < 0:
            # Avoids any cleverly crafted PNGs that would put the reader
            # in an infinite loop.
            ifp.close()
            ofp.close()
            return False

        if cktype != "tEXt" or ignore_existing == False:
            # Copies the chunks data and the checksum
            ofp.write(slen)
            ofp.write(cktype)
            ofp.write(ifp.read(cklen + 4))
        else:
            ifp.seek(cklen + 4, os.SEEK_CUR)

        # Writes the text chunks just after the header. If no header is found
        # nothing new will be written,  but this file is invalid anyway.
        if cktype == "IHDR" and written == False:
            for ck in chunks:
                _write_chunk(ofp, "tEXt", '\0'.join(ck))

        if cktype == "IEND":
            # End of file reached. Stops.
            ifp.close()
            ofp.close()
            return True

    # End of file reached without and IEND. Not so good.
    ifp.close()
    ofp.close()
    return True


def test_print_comments():
    """ Test function, for debug only. """
    import sys
    if len(sys.argv) != 2:
        print "File name required."
        return
    print read_text_chunks(sys.argv[1])

if __name__ == "__main__":
    test_print_comments()

