#!/usr/bin/env lua

-- sub2str.lua -- Converts .sub subtitles to .srt ones.
-- (c) 2005 Alexandre Erwin Ittner <aittner AT netuno.com.br>
-- Distributed under the GNU GPL v2 or above. WITHOUT WARRANTIES.
-- $Id: sub2srt.lua,v 1.2 2005/08/13 04:33:18 dermeister Exp $


function convert(ifp, ofp)
  local ln, s, e, st, et
  local ts1 = "([0-9][0-9]:[0-5][0-9]:[0-5][0-9],[0-9][0-9])"
  local ts2 = ts1 .. "," .. ts1
  local cnt = 1
  for ln in ifp:lines() do
    -- removes \r from Windows files on Unix, or \n on Macs.
    ln = string.gsub(ln, "[\n\r]+", "")
    if string.sub(ln, 1, 1) ~= "[" then
      s, e, st, et = string.find(ln, ts2)
      if st and et then 
        ofp:write(cnt .. "\n" .. st .. "0 --> " .. et .. "0\n")
        cnt = cnt + 1
      else
        ln = string.gsub(ln, "%[br%]", "\n")
        ofp:write(ln .. "\n")
      end
    end
  end
end


function usage()
  print("sub2str.lua -- Converts .sub subtitles to .srt ones.")
  print("(c) 2005 Alexandre Erwin Ittner <aittner AT netuno.com.br>")
  print("Distributed under the GNU GPL v2 or above. WITHOUT WARRANTIES.")
  print("")
  print("Usage: sub2str.lua [-i infile.sub] [-o outfile.srt] [--help]")
end


function die(ret, msg, ifp, ofp)
  if msg then
    print("ERROR: " .. msg)
  end
  if ifp then ifp:close() end
  if ofp then ofp:close() end
  os.exit(ret)
end


local ifp, ofp
local i = 1

while arg[i] do
  if arg[i] == "--help" then
    usage()
    die(0, nil, ifp, ofp)
  elseif arg[i] == "-i" then
    if ifp then
      die(1, "Input file already specified.", ifp, ofp)
    end
    i = i + 1
    if arg[i] then
      ifp = io.open(arg[i], "r")
      if not ifp then
        die(1, "Can't open input file.", ifp, ofp)
      end
    else
      die(1, "Input file not specified.", ifp, ofp)
    end
  elseif arg[i] == "-o" then
    if ofp then
      die(1, "Output file already specified.", ifp, ofp)
    end
    i = i + 1
    if arg[i] then
      ofp = io.open(arg[i], "w")
      if not ofp then
        die(1, "Can't open output file.", ifp, ofp)
      end
    else
      die(1, "Output file not specified.", ifp, ofp)
    end
  else
    die(1, "Bad command line argument.", ifp, ofp)
  end
  i = i + 1
end

convert(ifp or io.stdin, ofp or io.stdout)
die(0, nil, ifp, ofp)