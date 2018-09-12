# uinput.nim

##  gather data from keyboard devices(card scanner, bluetooth vernier caliper, etc.)

import os

import times
import streams
import strutils

import nigui
import parsetoml
#import redis
import json

import lib.db_redis
import lib.logging
import lib.utils

when defined(windows):
    let sep = "\\"
else:
    let sep = "/"
    
let path = getAppDir()
let config_path =  join([path, "conf", "input.toml"], sep=sep)

#create logs/ folder
let log_path =  join([path, "logs"], sep=sep)
# createDir(path)
discard existsOrCreateDir(log_path)

let config = get_config(config_path)

let app_conf = config["app"]

let MAX_LENGTH_VC = parsetoml.getInt(app_conf["max_length_vc"], 6)
let LENGTH_ID = parsetoml.getInt(app_conf["length_id"], 6)
let ws = parsetoml.getStr(app_conf["ws"], "10")

# id - empNo
let operators_db = config["operators"]
    
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
    
    var rdb = newRedisDB(config["redis"])
    let lua_fn = parsetoml.getStr(config["redis"]["enqueue_lua"],"enqueue.lua")    
    var fs = newFileStream(lua_fn, fmRead)    
    let lua_script = fs.readAll()
    
    var sha1:string
    
    if rdb.enable:
        sha1 = rdb.exec("SCRIPT", @["LOAD", lua_script])
        
    app.init()

    ##  var timer: Timer
    
    var window = newWindow("U-Input")
    window.width  = 860
    window.height  = 532

    var container = newLayoutContainer(Layout_Vertical)
    window.add(container)

    var inputContainer = newLayoutContainer(Layout_Horizontal)
    container.add(inputContainer)

    var label = newLabel("录入 ")
    inputContainer.add(label)

    # input
    var inputTextBox = newTextBox("")
    inputContainer.add(inputTextBox)
    
    var wslabel = newLabel(" 工位 ")
    #wslabel.width = 30    
    inputContainer.add(wslabel)

    # work station No
    var wsinputTextBox = newTextBox(ws)
    wsinputTextBox.width = 60
    wsinputTextBox.editable = false
    inputContainer.add(wsinputTextBox)
    
    var label2 = newLabel("""    注意切换至英文输入法！ """)
    inputContainer.add(label2)    

    var label3 = newLabel("历史记录")
    container.add(label3)

    var textShow = newTextBox("0.00")
    container.add(textShow)
    textShow.editable = false
    textShow.fontSize = 80
    textShow.fontFamily = "Tahoma"

    var logTextArea = newTextArea("")
    container.add(logTextArea)
    logTextArea.editable = false

    var footContainer = newLayoutContainer(Layout_Horizontal)
    container.add(footContainer)

    var button = newButton("清除记录")
    footContainer.add(button)

    var sepLabel = newLabel("  ::  ")
    footContainer.add(sepLabel)    
    
    var statusLabel = newLabel("")
    footContainer.add(statusLabel)
   
    ###########################################################################
    var createdon: string  
    # inputTextBox.onTextChange = proc(event: TextChangeEvent) =

    inputTextBox.onKeyDown = proc(event: KeyboardEvent) = 

        if event.key == Key_Return:
            
            if inputTextBox.text == "":
                return

            textShow.text = inputTextBox.text
            
            createdon = format(now(),"yyyy-MM-dd'T'HH:mm:ss")
            
            if rdb.enable:
                #debug("redis enable")
                # write data to redis
                
                # 0.00 - 156.08
                let text_len = len(inputTextBox.text)
                #let ws = wsinputTextBox.text
                var val : JsonNode#float
                
                # value from VC
                if text_len <= MAX_LENGTH_VC:
                    #val = parseFloat(inputTextBox.text)
                    val = %* {"time":createdon, "value": inputTextBox.text, "ws":ws, "type":"vc"}
                
                # value from Card
                elif text_len == LENGTH_ID:
                    
                    var emp_no:string
                    
                    if operators_db.hasKey(inputTextBox.text):
                        # get operator No
                        emp_no = parsetoml.getStr(operators_db[inputTextBox.text], "000")
                    else:
                        emp_no = "who"
                        
                    val = %* {"time":createdon, "card_id": inputTextBox.text, 
                              "emp_no":emp_no, "ws":ws, "type":"id"}
                    
                else:
                    val = %* {"time":createdon, "value": inputTextBox.text, 
                              "ws":ws, "type":"unknown"}
                    
                var rtn = rdb.exec("EVALSHA", @[sha1, "1",ws, createdon, $val])

                statusLabel.text = "status:"  & createdon & " " & rtn
                
            else:
                #debug("redis is not available")
                statusLabel.text = "status:"  & createdon & " no redis"
            # log
            logTextArea.text = createdon & " -> " & inputTextBox.text & "\p" & logTextArea.text
            
            debug(inputTextBox.text)
            
            inputTextBox.text = ""
            inputTextBox.focus()
            
    #########################
    logTextArea.onClick = proc(event: ClickEvent) = 
        inputTextBox.focus()
        
    #########################    
    textShow.onClick = proc(event: ClickEvent) = 
        inputTextBox.focus()
        
    wsinputTextBox.onClick = proc(event: ClickEvent) = 
        inputTextBox.focus()
    
    #########################
    button.onClick = proc(event: ClickEvent) = 
        logTextArea.text = ""
        inputTextBox.focus()
        
    ##  proc work(event: TimerEvent) =
        ##  timer.stop()
        ##  info("work...")
        ##  timer = startTimer(3000, work)
        
    ##  timer = startTimer(3000, work)

    window.show()
    
    inputTextBox.focus()
    app.run()

# main
when isMainModule:
    main()