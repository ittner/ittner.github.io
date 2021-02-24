#!/usr/bin/env lua

-- juliansign.lua -- An insane script to generate e-mail signatures with
-- the Julian Day. Some code is based on C code from Stellarium, thanks
-- Fabien Chéreau!
--
-- (c) 2005 Alexandre Erwin Ittner <aittner@netuno.com.br>
--
-- This program is free software; you can redistribute it and/or modify it
-- under the terms of the GNU Library General Public License as published
-- by the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
-- for more details.
-- 
-- You should have received a copy of the GNU General Public License along
-- with this program; if not, write to the Free Software Foundation, Inc.,
-- 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
--

local signtext = [[
-- 
<insert yout signature here>
Julian day ]]

local gmtoffset = -3




function getJulianDay()
  local y, m, b
  local dt = os.date("*t")
  local offset = gmtoffset

  y = dt.year
  m = dt.month
  if dt.month <= 2 then
    y = dt.year - 1
    m = dt.month + 12
  end

  -- Handles the stupid day light saving time
  if dt.isdst then
    offset = offset + 1
  end

  -- Correct for the lost days in Oct 1582 when the Gregorian calendar
  -- replaced the Julian calendar.
  b = -2
  if dt.year > 1582 or (dt.year == 1582 and (dt.month > 10 or
  (dt.months > 10 or (dt.month == 10 and dt.day >= 15)))) then
    b = math.floor(y/400.0) - math.floor(y/100.0)
  end
    
  return math.floor(365.25*y) + math.floor(30.6001 * (m+1)) + b
    + 1720996.5 + dt.day + dt.hour/24.0 + dt.min/1440.0 + dt.sec / 86400.0
    - offset/24.0
end


function numpunct(num)
  local numstr = tostring(num)
  local rstr = ""
  local _, c, i, estr, sstr

  _, _, sstr, estr = string.find(numstr, "([0-9]+)%.([0-9]+)")
  if not (sstr and estr) then
    sstr = numstr
    estr = "0"
  end

  while string.len(sstr) > 3 do
    rstr = "." .. string.sub(sstr, -3) .. rstr
    sstr = string.sub(sstr, 1, string.len(sstr) - 3)
  end
  return sstr .. rstr .. "," .. estr
end

local jd = getJulianDay()
io.write(signtext, numpunct(jd), "\n")

