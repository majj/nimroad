
#
# log_reversed.nim
#

## watchman for reversed log file

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

import logging
import parsetoml

import daemon

import utils


###################################################################
# get config
proc get_config(toml_fn:string):TomlValueRef =     

    let config = parsetoml.parseFile(toml_fn)    
    return config

let config = get_config("conf/watchman.toml")

# interval for sleep
let INTERVAL = parsetoml.getInt(config["app"]["interval"], 5000)

let PATTERN = parsetoml.getStr(config["app"]["pattern"], "*.nim")

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

proc append_new_content(path:string, seed:int64):void = 

    let content:string = read_new_content(path, seed)
    
    let output_fn:string = path & EXT
    
    if content != nil:
        var fstream = newFileStream(output_fn, fmAppend) 
        
        # reverse lines
        let lines = content.splitLines().reversed()
        
        for line in lines:
            fstream.write(line&"\r\n")
        
        fstream.close()

proc process(pattern:string):void =     
    
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
    var jsize:int = 0
    
    for path, kind in walkGlobKinds(pattern):
        
        let file_info = getFileInfo(path)
        
        let size:int = toU32(file_info.size)
        
        if journey.hasKey(path):
            
            var node = journey[path]
            
            jsize = node["size"].getInt()
            
            let size_diff:int = size - jsize
            
            if size_diff > 0:
                
                append_new_content(path, size_diff)
                
                journey[path] = %*{"id":file_info.id.file, 
                   "size":size, 
                   "lwtime":file_info.lastWriteTime.toUnix()}
                   
                update = true
                
        else:            
            append_new_content(path, size)
            
            journey[path] = %*{"id":file_info.id.file, 
               "size":size, 
               "lwtime":file_info.lastWriteTime.toUnix()}
            
            update = true
            
    if update == true:
        save_journey(journey)
    
proc loop():void = 

    while true:
        
        process(PATTERN)
        ## debug("sleep:",INTERVAL)
        sleep(INTERVAL)

proc main() =

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
