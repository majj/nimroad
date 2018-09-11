# gui01.nim

import os
import asyncdispatch
import times
import strutils


import nigui
import parsetoml
import redis

import json

import lib.logging
import lib.utils


when defined(windows):
    let sep = "\\"
else:
    let sep = "/"
    
let path = getAppDir()
let config_path =  join([path, "conf", "vc.toml"], sep=sep)

#create logs/ folder
let log_path =  join([path, "logs"], sep=sep)
# createDir(path)
discard existsOrCreateDir(log_path)

let config = get_config(config_path)


let redis_conf = config["redis"]
 
let redis_host = parsetoml.getStr(redis_conf["host"],"localhost")
let redis_port = parsetoml.getInt(redis_conf["port"],6379)
let redis_vckey = parsetoml.getStr(redis_conf["vckey"],"vckey")
let redis_queue = parsetoml.getStr(redis_conf["data_queue"],"data_queue")

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



proc main():void = 
    
    info("start...")
    
    var redc: AsyncRedis
    
    var redis_enable = false
    
    try:
        redc = waitFor redis.openAsync(redis_host, Port(redis_port))
        redis_enable = true
    except:
        error("can't open redis")
        
    app.init()

    ##  var timer: Timer
    
    var window = newWindow("Input")
    window.width  = 860
    window.height  = 532

    var container = newLayoutContainer(Layout_Vertical)
    window.add(container)

    var inputContainer = newLayoutContainer(Layout_Horizontal)
    container.add(inputContainer)

    var label = newLabel("录入 ")
    inputContainer.add(label)

    # input
    var textBox = newTextBox("")
    inputContainer.add(textBox)
    
    var wslabel = newLabel("工位 ")
    #wslabel.width = 30
    inputContainer.add(wslabel)

    # work station No
    var wsTextBox = newTextBox("10")
    wsTextBox.width = 60
    inputContainer.add(wsTextBox)
    
    var label2 = newLabel("    注意切换至英文输入法！ ")
    inputContainer.add(label2)    

    var label3 = newLabel("历史记录")
    container.add(label3)

    var textShow = newTextBox("0.00")
    container.add(textShow)
    textShow.editable = false
    textShow.fontSize = 80
    textShow.fontFamily = "Tahoma"

    var textArea = newTextArea("")
    container.add(textArea)
    textArea.editable = false

    textArea.onClick = proc(event: ClickEvent) = 
        textBox.focus()
    
    var createdon: string
    
    textBox.onKeyDown = proc(event: KeyboardEvent) = 

        if event.key == Key_Return:
            
            # send to redis here
            if textBox.text == "":
                return
            
            #textArea.addLine(textBox.text)
            textShow.text = textBox.text
            createdon = format(now(),"yyyy-mm-dd'T'hh:mm:ss")
            
            if redis_enable:
                # write data to redis
                
                # 0.00 - 156.08
                let text_len = len(textBox.text)
                let ws = wsTextBox.text
                var val : JsonNode#float
                
                if text_len < 7:
                    #val = parseFloat(textBox.text)
                    val = %* {"time":createdon, "value": textBox.text, "ws":ws, "type":"vc"}
                elif text_len == 8:
                    val = %* {"time":createdon, "value": textBox.text, "ws":ws, "type":"id"}
                else:
                    val = %* {"time":createdon, "value": textBox.text, "ws":ws, "type":"unknown"}
                    
                waitFor redc.setk(join([redis_vckey,"value"], sep=":"), $val)
                waitFor redc.setk(join([redis_vckey,"time"], sep=":"), createdon)
                discard waitFor redc.lPush(redis_queue, $val)
                
            #except:
            #    error("redis error")
                
            textArea.text = createdon & " -> " & textBox.text & "\p" & textArea.text
            
            debug(textBox.text)
            
            textBox.text = ""
            textBox.focus()            
        
    #textBox.onTextChange = proc(event: TextChangeEvent) =

    textShow.onClick = proc(event: ClickEvent) = 
        textBox.focus()

    var footContainer = newLayoutContainer(Layout_Horizontal)
    container.add(footContainer)

    var button = newButton("清除记录:")
    footContainer.add(button)

    var sepLabel = newLabel("  ::  ")
    footContainer.add(sepLabel)    
    
    var statusLabel = newLabel("")
    footContainer.add(statusLabel)    

    button.onClick = proc(event: ClickEvent) = 
        textArea.text = ""
        textBox.focus()
        
    ##  proc work(event: TimerEvent) =
        ##  timer.stop()
        ##  info("work...")
        ##  timer = startTimer(3000, work)
        
    ##  timer = startTimer(3000, work)

    window.show()
    textBox.focus()
    app.run()


when isMainModule:
    main()