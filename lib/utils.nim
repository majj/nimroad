
import parsetoml

import logging

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

proc get_clogger*(log_conf: TomlValueRef): ConsoleLogger =

    var clogger = logging.newConsoleLogger(lvlAll, "($datetime) [$levelid] -- $appname: ")
    
    return clogger

proc get_rlogger*(log_conf: TomlValueRef): RollingFileLogger = 

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

# test
when isMainModule:
    echo   GetCurrentProcessId()

