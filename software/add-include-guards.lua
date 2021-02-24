#!/usr/bin/lua

local usage_text = [[
Quick and dirty script to add include guards to header files
(c) 2010 Alexandre Erwin Ittner <alexandre (a) ittner # com # br>

== License ==

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

See http://www.gnu.org/licenses/gpl-2.0.html for the complete
license terms.


== Usage ==

Just run this script passing the header files to be guarded
against double inclusion as command line arguments. Eg.:

    ./add-include-guards.lua file1.h file2.h

the files will be updated in place.

]]


local io = require("io")
local table = require("table")
local os = require("os")

local function process_one_file(fname)
    if fname:sub(-2) ~= ".h" then
        io.stderr:write(fname, ": does not end in '.h'\n")
        return false
    end
    local fp = io.open(fname, "rb")
    if not fp then
        io.stderr:write(fname, ": failed to read file.\n")
        return false
    end
    local macroname = "_" .. fname:upper():gsub("[^A-Z0-9]", "_")
    local guard = "\n#ifndef " .. macroname .. "\n"
                .. "#define " .. macroname .. "\n"
                .. "#pragma once\n"
    local tbl = { }
    local line_cnt = 0
    local line_to_add = false
    while true do
        local line = fp:read("*l")
        if not line then break end
        line_cnt = line_cnt + 1
        if line:find(macroname) then
            io.stderr:write(fname, ": looks that this file already have ",
                "the guard in the line ", line_cnt, ", '", line, "'.\n")
            fp:close()
            return false
        end
        tbl[#tbl+1] = line
        if not line_to_add and line:gsub("%s", "") == "" then
            line_to_add = line_cnt      -- first blank line
        end
    end
    fp:close()

    if not line_to_add then
        return true     -- empty file?
    end
    table.insert(tbl, line_to_add, guard)
    tbl[#tbl+1] = "\n#endif  /* " .. macroname .. " */\n"

    local fp = io.open(fname, "wb")
    if not fp then
        io.stderr:write(fname, ": failed to update file.\n")
        return false
    end
    fp:write(table.concat(tbl, "\n"))
    if not fp:close() then
        io.stderr:write(fname, ": failed to close file.\n")
        return false
    end
    return true
end

if not arg or #arg < 1 then
    io.stderr:write(usage_text)
    os.exit(1)
end

local allok = true
for i = 1, #arg do
    allok = process_one_file(arg[i]) and allok
end

os.exit(allok and 0 or 1)

