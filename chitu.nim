
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

let rLogger = get_logger(log_conf)

logging.addHandler(rLogger)    


var msgs: Channel[string]

# timer for heartbeat
proc timer():void = 

    let line = "."
    let interval = 2000
    while true:
        
        msgs.send(line)

        sleep(interval)

proc worker():void = 

    while true:
        var msg = msgs.recv()
        echo msg

msgs.open()  # open channel

# main
proc main():void = 

    info("start...")
    
    var timer_thread = Thread[void]()
    var worker_thread = Thread[void]()

    createThread(timer_thread, timer)
    createThread(worker_thread, worker)

    joinThreads(timer_thread, worker_thread)    

# run main
if isMainModule:
    main()
