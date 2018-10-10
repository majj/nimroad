--[[

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

local channel = KEYS[1]
local device = KEYS[2]

