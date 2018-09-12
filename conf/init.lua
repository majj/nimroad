
-- redis.call("SET", "testuser", "mabo")

redis.call("HSET", "88888888", "id","0281866")
redis.call("HSET", "88888888", "user","op1")

redis.call("HSET", "12388888", "id","0111866")
redis.call("HSET", "12388888", "user","op2")

return 'OK'