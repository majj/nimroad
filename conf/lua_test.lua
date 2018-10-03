

local cjson = require "cjson"

local cmsgpack = require "cmsgpack"

local lpeg = require "lpeg"



local y = cjson.decode('{"21":"1","1x11":"hello"}')

print(cjson.encode(y))


