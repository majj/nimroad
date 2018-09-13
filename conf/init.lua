
-- redis.call("SET", "testuser", "mabo")

redis.call("HSET", "user:4253911283", "id","091866")
redis.call("HSET", "user:4253911283", "user","op1")

redis.call("HSET", "user:4253955683", "id","181633")
redis.call("HSET", "user:4253955683 ", "user","op2")

return 'OK'
