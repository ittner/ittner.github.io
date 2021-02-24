#!/usr/bin/env lua
--
-- makersslua - generates Atom/RSS feeds from static sites stored in Git
-- (c) 2009-2012 Alexandre Erwin Ittner <alexandre *at* ittner.com.br>
--
--
-- This program generates feeds from the static website files stored in Git
-- repositores; all information about the files is extracted from the
-- repository itself and the program generates UUIDs for each URL using the
-- SHA1 sum of its last update, so no external bookkeeping is needed and the
-- feed readers do never get confused. The output is saved to a local file
-- that must be uploaded to the server.
--
-- The program assumes that you update the website offline and then run some
-- kind of synchronization mechanism to send it to the server (rsync, FTP,
-- etc.). For example, I update my site by creating and editing the XHTML
-- files directly and commit the changes to the Git repository. After, I run
-- a script that processes the pages to update the menus and other common
-- content using a bunch of XSL templates, saves the output in a temporary
-- directory, generates the feed and then synchronizes to the server (I use
-- GitHub Pages, but this will also work with rsync, scp, or even FTP).
-- Maintaining a website this way may be appear unusual, but it's pretty
-- fast and, since I do not have any interest in providing any interactive
-- features, frees me of all administrative work with CMSs, blogs, database
-- servers and so long.
--
-- You will need to change the configuration variables bellow, hook this
-- script to your update workflow and ensure that all relevant files are
-- returned by the command given by FILE_LIST_CMD. You may also need to
-- change the filesystem -> URL converter function if it do not matches your
-- directory layout.
--
--
-- REQUERIMENTS
--
--  Lua 5.1 or later
--  Git 1.6 or later
--
--
-- USAGE
--
--  The program *must* run from inside the Git repository! Remember to take
--  the work directory in account when configuring the FILE_LIST_CMD.
--
--  ./makerss.lua                   Generates a RSS 2 feed to stdout.
--
--  ./makerss.lua <output.xml>      Generates an Atom feed to the given
--                                  output file (the Atom format needs
--                                  to reference to the current file name,
--                                  so sending to stdout will not work).
--
--
-- LICENSE
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place - Suite 330, Boston,
-- MA 02111-1307, USA.
--
--


-- Configuration variables (change according to your site)

local SITE_PREFIX = "http://www.example.com/"
local SITE_TITLE = "Title of your website"
local SITE_DESCRIPTION = "Website description"
local SITE_URL = SITE_PREFIX    -- URL of the site's index page
local SITE_TTL = "60"
local FILE_LIST_CMD = "ls *.html"



local function get_title(fname)
    local fp = assert(io.open(fname, "r"), "Failed to open file")
    local tx = fp:read(8192)    -- Title should be in the first 8K.
    fp:close()
    assert(tx, "No data found on file")
    return tx:match("<title>([^<]*)</title>")
end

local function get_last_revision(fname)
    local cmd = 'git log -n 1 --pretty="format:%%H;%%cD" %q'
    local fp = assert(io.popen(cmd:format(fname)), "Failed to start git")
    local line = fp:read("*l")
    fp:close()
    if line then
        return line:match("([0-9a-f]+);(.*)")
    end
    return nil
end

local function convert_fname_url(fname)
    if fname == "index.html" then
        return ""
    end
    -- URL enconding here.
    return fname
end

local function get_state()
    local lst = { }
    local fp = assert(io.popen(FILE_LIST_CMD), "Failed to get files")
    for fname in fp:lines() do
        local hash, date = get_last_revision(fname)
        local title = get_title(fname)
        if hash and date and title then
            lst[#lst+1] = { fname = fname, hash = hash, date = date,
                title = title, url = convert_fname_url(fname) }
        end
    end
    fp:close()
    return lst
end

function write_rss(fp, fname)
    local atomns = nil
    if fname then
        atomns = ' xmlns:atom="http://www.w3.org/2005/Atom"'
    end
    fp:write('<?xml version="1.0" encoding="utf-8" ?>',
        '<rss version="2.0"', atomns or "", '>',
            '<channel>',
                '<title>', SITE_TITLE, '</title>',
                '<link>', SITE_URL, '</link>',
                '<description>', SITE_DESCRIPTION, '</description>',
                '<ttl>', SITE_TTL, '</ttl>')
    if fname and atomns then
        fp:write('<atom:link href="', SITE_PREFIX, fname,
            '" rel="self" type="application/rss+xml" />')
    end
    for _, v in ipairs(get_state()) do
        fp:write(
            '<item>',
                '<title>', v.title, '</title>',
                '<link>', SITE_PREFIX, v.url, '</link>',
                '<description>', v.title, '</description>',
                '<guid>', SITE_PREFIX, v.url, '#', v.hash, '</guid>',
                '<pubDate>', v.date, '</pubDate>',
            '</item>')
    end
    fp:write('</channel>', '</rss>', '\n')
end


local fname = arg[1]
if fname then
    local fp = assert(io.open(fname, "w"), "Failed to open destination file")
    write_rss(fp, fname)
    fp:close()
else
    write_rss(io.stdout, nil)
end
