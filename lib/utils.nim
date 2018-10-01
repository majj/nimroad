
# =======
# Imports
# =======
import os

import parsetoml
import logging

# =========
# Functions
# =========

# get current process id
when defined(windows):
    proc GetCurrentProcessId*(): int32 {.stdcall, dynlib: "kernel32",
                                        importc: "GetCurrentProcessId".}
else :
  from posix import getpid
  
  proc  GetCurrentProcessId*():
    getpid()

# parse Toml
proc get_config*(toml_fn: string): TomlValueRef =     

    let config = parsetoml.parseFile(toml_fn)    
    return config

# helper for set logger

proc get_console_logger*(log_conf: TomlValueRef): ConsoleLogger =

    let fmtStr = parsetoml.getStr(log_conf["fmt"], "($datetime) [$levelid] -- $appname: ") 
    
    var clogger = logging.newConsoleLogger(lvlAll, fmtStr)
    
    return clogger

proc get_rolling_logger*(log_conf: TomlValueRef): RollingFileLogger = 

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
    
    return rLogger
    
# =====
# Types
# =====
type
    HApp* = ref object of RootObj  # HApp: helper App
        # common functions for the App
        config*: TomlValueRef
# ================
# Public Functions
# ================
proc newHApp*(): HApp = 

    let app_path = getAppDir()

    let conf_file_name = getAppFilename().splitFile().name&".toml"
    # get config path
    let config_path = joinPath(app_path, "conf", conf_file_name )
    # create logs/ folder
    let log_path =  joinPath(app_path, "logs")
    # createDir(path)
    discard existsOrCreateDir(log_path)

    let config = get_config(config_path)
    
    let log_conf = config["logging"]

    let rLogger = get_rolling_logger(log_conf)
    logging.addHandler(rLogger)
    
    ##  debug(conf_file_name)
    
    let ConsoleLog = parsetoml.getBool(config["app"]["console_log"], true)
    if ConsoleLog:
        let cLogger = get_console_logger(log_conf)
        logging.addHandler(cLogger)    

    return HApp(config: config)

# test
when isMainModule:
    echo   GetCurrentProcessId()

