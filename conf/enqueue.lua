--
--
--  keys[1]  workstation
--  args[1]  timestamp
--  args[2]  data (json_str)

local key = KEYS[1]
local timestamp = ARGV[1]
local data  = ARGV[2]    

redis.call("SET", "user:key", key)
redis.call("SET", "user:ts", timestamp)
redis.call("LPUSH", "data_queue", data)

return 'OK'

-- return cjson.decode(msg)["a"]
--return cjson.encode({["foo"]= "bar",["ts"]="123"})