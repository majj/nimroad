
import os
import net
import parsetoml

import struct  # nimble install struct
import logging

proc get_config(toml_fn:string):TomlValueRef =     

    let config = parsetoml.parseFile(toml_fn)    
    return config

let config = get_config("conf/ak_client.toml")

let app_conf = config["app"]
#echo(app_conf)

# for AK client
let HOST:string = parsetoml.getStr(app_conf["host"],"localhost")
let PORT:int = parsetoml.getInt(app_conf["port"], 9527)

let INTERVAL:int = parsetoml.getInt(app_conf["interval"], 5000)

let STX = char(2)
let ETX = char(3)

let COMMAND = parsetoml.getInt(app_conf["command"], 2)
let CLIENT_ID = parsetoml.getInt(app_conf["client_id"], 6)

let CMD_FMT:string = parsetoml.getStr(app_conf["cmd_fmt"], "!4b")
let DATA_FMT:string = parsetoml.getStr(app_conf["data_fmt"], "!4b")


proc initLogging(log_conf:TomlValueRef) =

    let fmtStr = parsetoml.getStr(log_conf["fmt"], "($datetime) [$levelid] -- $appname: ") 
    let log_file = parsetoml.getStr(log_conf["log_file"],"app.log")
    let max_lines = parsetoml.getInt(log_conf["max_lines"], 100)
    let backup_count = parsetoml.getInt(log_conf["backup_count"], 5)
    let buffer_size = parsetoml.getInt(log_conf["buffer_size"], 0)

    var rL = logging.newRollingFileLogger(log_file, mode = fmAppend, 
                                maxLines = max_lines, logFiles=backup_count, fmtStr = fmtStr, bufSize=buffer_size)
                                #maxLines = 300, fmtStr = fmtStr, bufSize=0)

    logging.addHandler(rL)


proc main():void = 

    # for logging
    let log_conf = config["logging"]
    initLogging(log_conf)
    
    info("starting AK client...")

    var query =  pack(CMD_FMT, STX, char(COMMAND), char(CLIENT_ID), ETX)    
    var qdata = unpack(CMD_FMT, query)
    #echo(qdata)

    var socket = newSocket()

    socket.connect(HOST, net.Port(PORT))

    while true:
        
        socket.send(query)
        
        var data = ""

        while true:
            try:
                data = data & socket.recv(1, timeout = 10)
            except:
                break
        
        if data.len > 0:

            var result = unpack(DATA_FMT, data)

            echo(result)
            #echo result[0].getChar()
            #echo result[5].getFloat()
        info("done!")
        sleep(INTERVAL)

    socket.close()
    
when isMainModule:
    
    main()