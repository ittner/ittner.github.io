#!/usr/bin/env lua

--
-- srtdelta.lua -- Adjust times on srt subtitles.
--
-- (c) 2005-12 Alexandre Erwin Ittner <alexandre AT ittner NOSPAM DOT com DOT br>
-- Distributed under the GNU GPL v2 or above. WITHOUT WARRANTIES.
--
--
-- Syntax: srtdelta.lua <timediff>
--
-- The command read the input subtitle data from the standard input and
-- prints the updated data on standard output. <timediff> is the time
-- difference between them, in seconds (fractions accepted).
--
--
-- Examples:
--
--  cat oldsubs.srt | srtdelta.lua 0.5 > newsubs.srt
--      Generate a new subtitle file 'newsubs.srt' with all subtitles
--      delayed by 500 milliseconds  (0.5 s).
--
--  cat oldsubs.srt | srtdelta.lua -0.5 > newsubs.srt
--      Note the minus sign! Generate a new subtitle file 'newsubs.srt'
--      with all subtitles advanced by 500 milliseconds (0.5 s).
--


local function time_join(h, m, s, f)
  return 3600 * h + 60 * m + s + 0.001 * f
end

local function time_fmt(tm)
  local h = math.floor(tm/3600.0)
  local m = math.floor(math.mod(tm, 3600)/60.0)
  local s = math.floor(tm - 3600*h - 60*m)
  local f = math.floor(1000*(tm - 3600*h - 60*m - s))
  return string.format("%02d:%02d:%02d,%03d", h, m, s, f)
end

assert(arg[1], "Error: no time delay given on command line.")

local delta = tonumber(arg[1])
assert(delta, "Error: delay time is not a valid number")

local ttp = "(%d+):(%d+):(%d+),(%d+)"
local pat = ttp .. "%s+%-%->%s+" .. ttp

local line, h1, m1, s1, f1, h2, m2, s2, f2, _

for line in io.lines() do
  _, _, h1, m1, s1, f1, h2, m2, s2, f2 = string.find(line, pat)
  if f2 then
    print(time_fmt(time_join(h1, m1, s1, f1) + delta) .. " --> " ..
      time_fmt(time_join(h2, m2, s2, f2) + delta))
  else
    print(line)
  end
end
