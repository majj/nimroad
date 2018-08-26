
#
# log_reversed.nim
#

## watchman for reversed log file

# rejistry file for filebeat:
#
# [{"source":"C:\\Temp\\filebeat-6.2.4-windows-x86_64\\log\\test.log",
#   "offset":2046,
#   "timestamp":"2018-05-29T23:34:59.4767001+08:00",
#   "ttl":-2,
#   "type":"log",
#   "FileStateOS":{"idxhi":2621440,"idxlo":300667,"vol":2794401243}}]

import algorithm
import glob
import os
import json
import tables
import streams
import strutils
import system
import times

##  import osproc
##  import winlean # for windows

import parsetoml
import daemon

import lib.logging
import lib.utils


###################################################################
# get config
proc get_config(toml_fn:string):TomlValueRef =     

    let config = parsetoml.parseFile(toml_fn)    
    return config

let config = get_config("conf/watchman.toml")

# interval for sleep
let INTERVAL = parsetoml.getInt(config["app"]["interval"], 5000)

let PATTERN = parsetoml.getStr(config["app"]["pattern"], "*.nim")
let LOG_REVERSED = parsetoml.getBool(config["app"]["log_reversed"], true)

let JOURNEY_FILE = parsetoml.getStr(config["app"]["journey"], "journey.json")
let EXT = parsetoml.getStr(config["app"]["ext"], ".log")

###################################################################
# set logging
let log_conf = config["logging"]
let fmtStr = parsetoml.getStr(log_conf["fmt"], "($datetime) [$levelid] -- $appname: ") 
let log_file = parsetoml.getStr(log_conf["log_file"], "app.log")
let log_level_str = parsetoml.getStr(log_conf["log_level"], "All")
let max_lines = parsetoml.getInt(log_conf["max_lines"], 3000)
let backup_count = parsetoml.getInt(log_conf["backup_count"], 5)
let buffer_size = parsetoml.getInt(log_conf["buffer_size"], 0)

var log_level:Level

case log_level_str    
    of "Debug": log_level = lvlDebug
    of "Info": log_level = lvlInfo
    of "Notice": log_level = lvlNotice
    of "Warn": log_level = lvlWarn
    of "Error": log_level = lvlError
    of "Fatal": log_level = lvlFatal
    of "None": log_level = lvlNone
    else: log_level = lvlAll

var rLogger = logging.newRollingFileLogger(log_file, mode = fmAppend, levelThreshold = log_level,
                            maxLines = max_lines, logFiles=backup_count, fmtStr = fmtStr, bufSize=buffer_size)
                            #maxLines = 300, fmtStr = fmtStr, bufSize=0)

logging.addHandler(rLogger)

###################################################################

proc save_journey(journey:JsonNode):void =
    
    info("save journey")
    
    var fstream = newFileStream(JOURNEY_FILE, fmWrite)
    fstream.write(journey.pretty())
    fstream.close()

proc read_new_content(file_name:string, size:int64):string =

    var fs = newFileStream(file_name, fmRead)

    if not isNil(fs):
        fs.setPosition(0)
        var new_content = fs.readStr(int(size))
        fs.close()

        return new_content
    else:
        return nil

proc process_new_content(path:string, seed:int64):void = 

    let content:string = read_new_content(path, seed)
    
    let output_fn:string = path & EXT
    
    if content != nil:
        var fstream = newFileStream(output_fn, fmAppend) 
        
        # reverse lines
        if LOG_REVERSED == true:
            let lines = content.splitLines().reversed()
       
            for line in lines:
                fstream.write(line&"\r\n") # or \n ?
        else:
            info("process")
            
        fstream.close()

proc process(pattern:string):void =     
    #
    # TODO: file rename
    #
    #let matcher = glob(pattern)
    
    #var journey = parseJson("""{"watchman_ver": 0.1}""")
    
    if not existsFile(JOURNEY_FILE):
        save_journey(%*{})
        
    var journey:JsonNode
    
    try:
        journey = json.parseFile(JOURNEY_FILE)
        
    except JsonParsingError:
        let msg = getCurrentExceptionMsg()
        error(msg)
        return
        
    var update:bool = false
    var offset:int = 0
    
    for path, kind in walkGlobKinds(pattern):
        
        let file_info = getFileInfo(path)
        
        let size:int = toU32(file_info.size)
        
        if journey.hasKey(path):
            
            var node = journey[path]
            
            offset = node["offset"].getInt()
            
            let size_diff:int = size - offset
            
            if size_diff > 0:
                
                process_new_content(path, size_diff)
                
                echo file_info.id.device, file_info.id.file
                journey[path] = %*{"id":file_info.id.file, 
                   "offset":size, 
                   "lwtime":file_info.lastWriteTime.toUnix()}
                   
                update = true
                
        else:            
            process_new_content(path, size)
            
            journey[path] = %*{"id":file_info.id.file, 
               "offset":size, 
               "lwtime":file_info.lastWriteTime.toUnix()}
            
            update = true
            
    if update == true:
        save_journey(journey)
    
proc loop():void = 

    while true:
        
        process(PATTERN)
        ## debug("sleep:",INTERVAL)
        sleep(INTERVAL)

proc main():void =

    info("start watchman...")
    loop()
        
proc main_daemonize():void =
    # BUG: focked many process when deamonize
    
    info("start watchman...")
    
    let main_pid = GetCurrentProcessId() 
    
    let res = daemonize("log_reversed.pid")
    
    debug(main_pid, " - ", res)
    
    if res == 0:
        debug("forked process run...")
        loop()
    else:
        debug("parent process exit...")


when isMainModule:
    main()
