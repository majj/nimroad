
##
##  
##  get data from redis (msgpack, json)
##  
##  send data to influxdb(cluster)
##  
##  if sink failed then retry n times.
##  all failed then save data to redis (retry queue)
##  when send failed,send alert(smtp)
##  ping influxdb when there is communication issue.
##

import os
import strutils

import parsetoml

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

# timer for heartbeat
proc timer(interval: int) {.thread.} = 

    let line = "."
    #let interval = 2000
    while true:
        
        msgs.send(line)
        echo getThreadID(),":sent"
        sleep(interval)

proc worker(val: int) {.thread.} = 

    while true:
        var msg = msgs.recv()
        echo getThreadID(), ":",msg, val

msgs.open()  # open channel

# main
proc main():void = 

    info("start...")
    
    var timer_thread = Thread[int]()
    var worker_thread = Thread[int]()

    createThread[int](timer_thread, timer, 1000)
    createThread[int](worker_thread, worker, 1000)

    #joinThreads(timer_thread, worker_thread)    
    
    while true:
        
        sleep(1000)

# run main
if isMainModule:
    main()
