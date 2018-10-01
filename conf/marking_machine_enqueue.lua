
-- Marking Machine
-- Format£º M1T(P)[SP]X+12345.678mm[SP]Y-12345.678mm[SP]Z+12345.678mm[LF][CR]
-- unit: mm
-- P:Test Point£¬T:Trace
-- "M1T X+12.68mm Y-15.79mm Z+25.68mm\r\n"


local workstation = KEYS[1]

local timestamp = ARGV[1]
-- input string
local input  = ARGV[2]
-- gsub: remove \r\n
input = input:gsub("^%s*(.-)%s*$", "%1")
-- output table
local output={}
local sep = "%s"
local i=1

local output_json
-- workstation
output['ws'] = workstation
-- timrestamp
output['ts'] = tonumber(timestamp)

for str in string.gmatch(input, "([^"..sep.."]+)") do
    
    if i == 1 then 
        output['type'] = string.sub(str, 3)
    else
        output[string.lower(string.sub(str, 1,1))] 
                =  tonumber(string.sub(str, 2, -3))
    end
    
    i = i + 1
end
-- output json
output_json = cjson.encode(output)
-- SET
redis.call("SET", "MarkingMachine",output_json)
-- RPOP
return output_json