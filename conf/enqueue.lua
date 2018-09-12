--
--
--  KEYS[1]  workstation
--  ARGV[1]  timestamp
--  ARGV[2]  data (json_str)

local workstation = KEYS[1]

local timestamp = ARGV[1]
local value  = ARGV[2]


local len = string.len(value)

local data

if len < 7 then
    data = cjson.encode({["time"] = timestamp, ["ws"]=workstation, 
                         ["value"] = value, ["type"] = "vc"})
elseif len == 8 then
    
    local emp_no = redis.call("HGET", value, "id")
    
    if emp_no then    
        data = cjson.encode({["time"] = timestamp, ["ws"]=workstation, 
                             ["value"] = value, ["empno"] = emp_no, ["type"] = "id"})
    else 
        data = cjson.encode({["time"] = timestamp, ["ws"]=workstation, 
                             ["value"] = value, ["empno"] = "who", ["type"] = "id"})
    end
        
else
    data = cjson.encode({["time"] = timestamp, ["ws"]=workstation, 
                         ["value"] = value, ["strlen"] = "msg"})
end
-- local emp_no = redis.call("HGET", "12388888", "id")

--- redis.call("SET", "user:key", key)
--- redis.call("SET", "user:id", emp_no)
redis.call("LPUSH", "data_queue", data)

return 'OK'

-- return cjson.decode(msg)["a"]
-- return cjson.encode({["foo"]= "bar",["ts"]="123"})