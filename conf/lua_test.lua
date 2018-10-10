

local cjson = require "cjson"

local cmsgpack = require "cmsgpack"

local lpeg = require "lpeg"







local ts = os.time()
local val = math.cos(ts)
print(val)

print(ts)

local t = cjson.encode({ts=ts, val = "val="..val })

local y = cjson.decode(t)

print(cjson.encode(y))