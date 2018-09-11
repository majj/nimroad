
import asyncdispatch

import parsetoml
import redis

type 
    DB*  = ref object of RootObj

        enable*: bool
        
        config: TomlValueRef
        redc: AsyncRedis     

proc newDB*(config: TomlValueRef): DB = 
    
    let redis_conf = config["redis"]
    let redis_host = parsetoml.getStr(redis_conf["host"],"localhost")
    let redis_port = parsetoml.getInt(redis_conf["port"],6379)

    try:
        let redc = waitFor redis.openAsync(redis_host, Port(redis_port))        
        return DB(config: redis_conf, redc: redc, enable: true)
    except:
        return DB(config: redis_conf, enable: false)        
        
proc set*(self: DB, key:string, data: string):void = 
    waitFor self.redc.setk(key, data)
        
proc push*(self: DB, key:string, data: string):void = 
    discard waitFor self.redc.lPush(key, data)