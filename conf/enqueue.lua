--
--
--  KEYS[1]  workstation
--  ARGV[1]  timestamp
--  ARGV[2]  value

local workstation = KEYS[1]

local timestamp = ARGV[1]
local value  = ARGV[2]


local len = string.len(value)

local data
local emp_no

if len <=6 then
    data = cjson.encode({["time"] = timestamp, ["ws"]=workstation, 
                         ["value"] = value, ["type"] = "vc"})
elseif len == 10 then
    
    emp_no = redis.call("HGET", "user:"..value, "id")
    
    if emp_no then    
        data = cjson.encode({["time"] = timestamp, ["ws"]=workstation, 
                             ["value"] = value, ["empno"] = emp_no, ["type"] = "id"})
    else 
        data = cjson.encode({["time"] = timestamp, ["ws"]=workstation, 
                             ["value"] = value, ["empno"] = "who", ["type"] = "id"})
        emp_no = "who"
    end
        
else
    data = cjson.encode({["time"] = timestamp, ["ws"]=workstation, 
                         ["value"] = value, ["strlen"] = "msg"})
end
-- local emp_no = redis.call("HGET", "12388888", "id")

--redis.call("SET", "value", value)
--- redis.call("SET", "user:id", emp_no)

redis.call("LPUSH", "data_queue", data)

if emp_no then
    return emp_no
else
    return value
end

-- return cjson.decode(msg)["a"]
-- return cjson.encode({["foo"]= "bar",["ts"]="123"})