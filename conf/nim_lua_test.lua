

local cjson = require "cjson"

local cmsgpack = require "cmsgpack"

local lpeg = require "lpeg"

p = lpeg.R"az"^1 * -1

--~ print(p:match("hello"))        --> 6
--~ print(lpeg.match(p, "hello"))  --> 6
--~ print(p:match("1 hello"))      --> nil

function split (s, sep)
  sep = lpeg.P(sep)
  local elem = lpeg.C((1 - sep)^0)
  local p = elem * (sep * elem)^0
  return lpeg.match(p, s)
end

-- print(split("abc;def;gi", ';'))

local function add(x)
    x = x + 10
    return x
end

local iii = geti()[getj()]

local args = ARGS()
local xxx = cjson.decode(args)

local y = cjson.decode('{"21":"1","1x11":"hello"}')

local z = cmsgpack.pack(y)

local z1 = cmsgpack.unpack(z)

--~ for k,v in pairs(z1) do
--~     print(k)
--~     print(v)
--~ end

local x = {["y1"]="1",["1x11"]=y["1x11"], y = add(23), z=iii, args=xxx}

--print(cjson.encode(x))

return cjson.encode(x)

