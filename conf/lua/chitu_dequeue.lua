--[[

-- cjson
-- cmsgpack
-- struct

-- luac 

raw data(decode)
    json
    msgpack
    struct

analysis
    lpeg
    string
    
return encode() to json, to influxdb line protocol
?? to Nim JSON directly?

--]]

--  KEYS[1]  channel (workstation)
--  KEYS[2]  device(equipment, machine)
--  tag

-- local channel = KEYS[1]
-- local device = KEYS[2]

-- "M1T X+12.68mm Y-15.79mm Z+25.68mm\r\n"


local M = {}

local function new()

end

print(package.cpath)

print(package.path)

M.i = 10
M.new = new

print(M.i)

for k, v in pairs(M) do
    print(k, v)
    print(M[k])
    
end

return M