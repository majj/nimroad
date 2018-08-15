
##
##  heartbeat to log file
##  heartbeat to redis
##
##  TODO: 
##  heartbeat to mqtt
##  heartbeat to influxdb
##  heartbeat to etcd
##  



import asyncdispatch
import os
import logging
import times
import json
#import streams

#, net, asyncnet, strutils, parseutils, deques, options
import parsetoml
import redis

proc get_config(toml_fn:string):TomlValueRef =     

    let config = parsetoml.parseFile(toml_fn)    
    return config

let config = get_config("conf/heartbeat.toml")

# interval for sleep
let interval = parsetoml.getInt(config["app"]["interval"], 5000)

###################################################################
# for logging
let log_conf = config["logging"]
let fmtStr = parsetoml.getStr(log_conf["fmt"], "($datetime) [$levelid] -- $appname: ") 
let log_file = parsetoml.getStr(log_conf["log_file"],"app.log")
let max_lines = parsetoml.getInt(log_conf["max_lines"], 100)
let backup_count = parsetoml.getInt(log_conf["backup_count"], 5)
let buffer_size = parsetoml.getInt(log_conf["buffer_size"], 0)


var rL = logging.newRollingFileLogger(log_file, mode = fmAppend, 
                            maxLines = max_lines, logFiles=backup_count, fmtStr = fmtStr, bufSize=buffer_size)
                            #maxLines = 300, fmtStr = fmtStr, bufSize=0)

logging.addHandler(rL)

###################################################################
# for redis
let redis_conf = config["redis"]
 
let redis_host = parsetoml.getStr(redis_conf["host"],"localhost")
let redis_hbkey = parsetoml.getStr(redis_conf["hbkey"],"hb")
var redis_enable = parsetoml.getBool(redis_conf["enable"],false)

var red:AsyncRedis

if redis_enable:
    try:
        red = waitFor redis.openAsync(redis_host, port=6379.Port)
        #echo("redis_enable:",redis_enable)
    except:
        error("can't open redis")
        redis_enable = false

proc redis_heartbeat(time_str:string):void = 
    
    waitFor red.setk(redis_hbkey, time_str)

proc main():int =

    ##  info("================main================")
    ##  info(config.toJson.pretty)
    info("start heartbeat...")
    
    while true:
        
        try:
            var time_str:string = format(now(), "yyyy-MM-dd'T'HH-mm-sszzz")
            if redis_enable:
                redis_heartbeat(time_str)            
            warn(time_str)            
        except:
            error("error")
        finally:
            info("done!")
            sleep(interval)
            
    return 1

when isMainModule:

    discard main()