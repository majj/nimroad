
# db_redis.nim
# 
# nimble install https://github.com/xmonader/nim-redisclient
#

import asyncdispatch

import parsetoml

import redisparser 
import redisclient

import logging

type 
    RedisDB*  = ref object of RootObj

        enable*: bool
        
        config: TomlValueRef
        redc: Redis    #echo redc.type.name

proc newRedisDB*(config: TomlValueRef): RedisDB = 

    let host = parsetoml.getStr(config["host"],"localhost")    
    let port = parsetoml.getInt(config["port"], 6379)    
    try:
        let redc = open(host, Port(port))        
        return RedisDB(config:config, redc:redc, enable:true)
    except:
        error("no redis")
        return RedisDB(config:config, enable:false)

proc exec*(self:RedisDB, cmd:string, params:seq[string]):string =
    if self.enable:
        return $self.redc.execCommand(cmd, params)
    else:
        return "N"