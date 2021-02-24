#!/usr/bin/python
# -*- encoding: utf-8 -*-
#
# bookmarks.py - Extract tagged entries from the Firefox bookmark DB
# (c) 2010 Alexandre Erwin Ittner <alexandre@ittner.com.br>
#
# This script extracts the urls, titles and descriptions with a given tag
# ("publicar", but you can change this, see bellow) from the Firefox
# bookmarks database. This is not a perfect, user-friendly or polished
# program, but a quick hack that I wrote to get a job done. 
#
#
# ------------------------------------------------------------------------
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
# ------------------------------------------------------------------------
#
#

import sqlite3
import os
import sys
import cgi

# Set the full path for your places.sqlite here. Check ~/.mozilla/firefox/
FNAME = "/home/youruser/.mozilla/firefox/xxxxxxxxxx/places.sqlite"

HEADER = u""" <!-- add your header here --> """

FOOTER = u""" <!-- add your footer here --> """


con = sqlite3.connect(FNAME)
try:

    #
    # Finds all bookmark entries with the given tag ('publicar'). Edit the
    # "moz_bookmarks.title = 'publicar'" to reflect your own tag if needed.
    #
    # Firefox uses a very clever database to hold history, bookmarks,
    # annotations, and typed addresses in the same place. The schema is
    # documented in https://developer.mozilla.org/en/The_Places_database
    # But beware: it may hurt the sensible eyes of the NoSQL weenies :)
    #
    # The code bellow is neither the best nor the fastest, but the easier to
    # write, read, and understand -- I think it is a good compromise, given
    # the objectives of this code.
    #

    cur = con.cursor()
    cur.execute("""
SELECT DISTINCT
    moz_places.url AS url,
    moz_bookmarks.title AS title,
    moz_items_annos.content AS description

FROM
    moz_places,
    moz_bookmarks,
    moz_items_annos,
    moz_anno_attributes

WHERE
    moz_anno_attributes.name = 'bookmarkProperties/description'
    AND moz_items_annos.anno_attribute_id = moz_anno_attributes.id
    AND moz_items_annos.item_id = moz_bookmarks.id
    AND moz_places.id = moz_bookmarks.fk
    AND moz_places.id IN (
            SELECT DISTINCT fk FROM moz_bookmarks
            WHERE parent IN (
                SELECT moz_bookmarks.id
                FROM moz_bookmarks, moz_bookmarks_roots
                WHERE moz_bookmarks_roots.root_name = 'tags'
                AND moz_bookmarks.parent = moz_bookmarks_roots.folder_id
                AND moz_bookmarks.title = 'publicar'
            )
        )
        
ORDER BY UPPER(moz_bookmarks.title) ASC
""")
except sqlite3.OperationalError:
    print("Failed to open the database. Is Firefox running?")
    exit()


print(HEADER.encode("utf-8"))

for t in cur:
    url = cgi.escape(t[0]).encode("utf-8", "xmlcharrefreplace")
    title = cgi.escape(t[1]).encode("utf-8", "xmlcharrefreplace")
    descr = cgi.escape(t[2]).encode("utf-8", "xmlcharrefreplace")

    sys.stdout.write('<li><a href="' + url + '">')
    if title and title != "":
        sys.stdout.write(title)
    else:
        sys.stdout.write(url)
    sys.stdout.write("</a>")
    if descr and descr != "":
        sys.stdout.write(" - ")
        sys.stdout.write(descr)
    sys.stdout.write("</li>\n")

print(FOOTER.encode("utf-8"))

