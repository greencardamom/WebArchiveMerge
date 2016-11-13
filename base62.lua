#!/usr/bin/lua

-- Given a Webcite ID on arg[1], return dates in mdy|dmy|iso|ymd format
--   example ID: 6H8pdR68H

-- http://convertxy.com/index.php/numberbases/
-- http://www.onlineconversion.com/unix_time.htm


--[[--------------------------< base62 >-----------------------

     Convert base-62 to base-10
     Credit: https://de.wikipedia.org/wiki/Modul:Expr 

  ]]

local function base62( value )

    local r = 1

    if value:match( "^%w+$" ) then
        local n = #value
        local k = 1
        local c
        r = 0
        for i = n, 1, -1 do
            c = value:byte( i, i )
            if c >= 48  and  c <= 57 then
                c = c - 48
            elseif c >= 65  and  c <= 90 then
                c = c - 55
            elseif c >= 97  and  c <= 122 then
                c = c - 61
            else    -- How comes?
                r = 1
                break    -- for i
            end
            r = r + c * k
            k = k * 62
        end -- for i
    end
    return r
end 

local function main()

  -- "!" in os.date means use GMT 

  zday = os.date("!%d", string.sub(string.format("%d", base62(arg[1])),1,10) )
  day = zday:match("0*(%d+)")                                                             -- remove leading zero
  zmonth = os.date("!%m", string.sub(string.format("%d", base62(arg[1])),1,10) )
  month = zmonth:match("0*(%d+)")
  nmonth = os.date("!%B", string.sub(string.format("%d", base62(arg[1])),1,10) ) 
  year = os.date("!%Y", string.sub(string.format("%d", base62(arg[1])),1,10) )

  mdy = nmonth .. " " .. day .. ", " .. year
  dmy = day .. " " .. nmonth .. " " .. year
  iso = year .. "-" .. zmonth .. "-" .. zday
  ymd = year .. " " .. nmonth .. " " .. day  

  year = tonumber(year)
  month = tonumber(month)
  day = tonumber(day)

  if year < 1970 or year > 2020 then
    print "error"
  elseif day < 1 or day > 31 then
    print "error"
  elseif month < 1 or month > 12 then
    print "error"
  else
    print(mdy .. "|" .. dmy .. "|" .. iso .. "|" .. ymd)
  end 

end

main()
