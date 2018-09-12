--
--
--  KEYS[1]  workstation
--  ARGV[1]  timestamp
--  ARGV[2]  data (json_str)

local key = KEYS[1]
local timestamp = ARGV[1]
local data  = ARGV[2]

-- local emp_no = redis.call("HGET", "12388888", "id")

--- redis.call("SET", "user:key", key)
--- redis.call("SET", "user:id", emp_no)
redis.call("LPUSH", "data_queue", data)

return 'OK'

-- return cjson.decode(msg)["a"]
-- return cjson.encode({["foo"]= "bar",["ts"]="123"})