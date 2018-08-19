
##
##  
##  get data from redis (msgpack, json)
##  
##  send data to influxdb(cluster)
##  
##  if sink failed then save data to sqlite (retry queue)
##  when send failed,send alert(smtp)
##  when failed then ping influxdb.
##

import os
import strutils
import times
import asyncdispatch

import typetraits

import parsetoml
import redis

import lib.logging
import lib.utils

when defined(windows):
    let sep = "\\"
else:
    let sep = "/"

####################################################################
##prepare

# getCurrentDir
#let app_name = getAppFilename()    

#get config path
let path = getAppDir()
let config_path =  join([path, "conf", "watchman.toml"], sep=sep)

#create logs/ folder
let log_path =  join([path, "logs"], sep=sep)
# createDir(path)
discard existsOrCreateDir(log_path)

let config = get_config(config_path)

echo toTomlString(config["app"])

let log_conf = config["logging"]

let rLogger = get_rlogger(log_conf)
logging.addHandler(rLogger)

let cLogger = get_clogger(log_conf)
logging.addHandler(cLogger)

var msgs: Channel[string]
var output: Channel[string]


# timer for heartbeat
proc timer(config: TomlValueRef) {.thread.} = 

    let line  = "."
    let interval = 2000
    while true:
        
        msgs.send(line)
        echo getThreadID(),":sent"
        sleep(interval)

proc worker(config: TomlValueRef) {.thread.} = 

    let redis_conf = config["redis"]
     
    let redis_host = parsetoml.getStr(redis_conf["host"],"localhost")
    let redis_hbkey = parsetoml.getStr(redis_conf["hbkey"],"heartbeat")
    let redis_dqkey = parsetoml.getStr(redis_conf["dqkey"],"data_queue")

    var redis_enable = parsetoml.getBool(redis_conf["enable"],false)
    
    var red:AsyncRedis
    
    if redis_enable:
        try:
            red = waitFor redis.openAsync(redis_host, port=Port 6379)
        except:
            error("can't open redis")
            redis_enable = false
            
    while true:
        try:
            var msg = msgs.recv()
            echo getThreadID(), ":",msg
            
            var time_str:string = format(now(), "yyyy-MM-dd'T'HH:mm:sszzz")
            output.send(time_str)
            #echo getThreadID(), ":",time_str
            waitFor red.setk(redis_hbkey, time_str)
        except:
            error("")
        
proc sink(config: TomlValueRef){.thread.} = 
    
    # get data and send to influxdb, when failed then save to sqlite
    
    while true:
        try:
            var output = output.recv()
            echo "sink",output
            sleep(1000)
        except:
            error("")

msgs.open()  # open channel
output.open()

# main
proc main():void = 

    info("start...")
    
    var timer_thread = Thread[TomlValueRef]()
    var worker_thread = Thread[TomlValueRef]()
    var sink_thread = Thread[TomlValueRef]()

    echo timer_thread.type.name
    echo worker_thread.type.name
    echo sink_thread.type.name
    
    createThread[TomlValueRef](timer_thread, timer, config)
    createThread[TomlValueRef](worker_thread, worker, config)
    createThread[TomlValueRef](sink_thread, sink, config)
    
    var workers_a: seq[Thread[TomlValueRef]]
    
    workers_a = @[timer_thread, worker_thread, sink_thread]
    
    #joinThreads(timer_thread, worker_thread)    
    
    while true:
        
        ##  echo "timer_thread:",timer_thread.running()
        ##  echo "worker_thread:",worker_thread.running()
        ##  echo "sink_thread:",sink_thread.running()
        
        for item in workers_a:
            echo item.running()
        
        sleep(1000)

# run main
if isMainModule:
    main()