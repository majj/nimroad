
# db_redis.nim
# 
# nimble install https://github.com/xmonader/nim-redisclient
#

## Example
## -------
##
## .. code-block::nim
##
##
##


import asyncdispatch

import parsetoml

import redisparser 
import redisclient

import logging

type 
    RedisDB*  = ref object of RootObj

        enable*: bool
        
        config: TomlValueRef
        host: string
        port: Port
        
        redc: Redis    #echo redc.type.name

proc newRedisDB*(config: TomlValueRef): RedisDB = 

    let host = parsetoml.getStr(config["host"],"localhost")    
    let port = parsetoml.getInt(config["port"], 6379)    
    try:
        let redc = open(host, Port(port))
        # enable = true
        return RedisDB(config:config, redc:redc, enable:true)
    except:
        error("no redis")
        # enable = false
        return RedisDB(config:config, enable:false)
        
proc reconnect(self:RedisDB): bool = 

    return true

proc exec*(self:RedisDB, cmd:string, params:seq[string]):string =
    if self.enable:  
        return  $self.redc.execCommand(cmd, params)
    else:
        return "N"