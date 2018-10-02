## marking_machine.nim

import os
import strutils
import streams
import times

import serial # Or: `import serial/utils`
import parsetoml

import lib/db_redis
import lib/logging
import lib/utils

let hApp = newHApp()
let config = hApp.config

proc get_ports():seq[string] = 

    var port_list:seq[string]
    
    for port in listSerialPorts():
        ##  echo port
        port_list.add(port)
          
        #info(port)
    return port_list  
    
proc main() = 

    info("start...")    

    let port_list = get_ports()
    
    info("RS232 Ports: " & port_list.join(sep=","))
    
    let INTERVAL = parsetoml.getInt(config["app"]["interval"])
    
    ## rs232
    let machine = config["machine"]
    
    let portName = parsetoml.getStr(machine["port"])
    let baud_rate = int32(parsetoml.getInt(machine["baudRate"]))
    let byteSize = byte(parsetoml.getInt(machine["byteSize"]))
    let parity = parsetoml.getInt(machine["parity"])
    let stopBits = parsetoml.getInt(machine["stopBits"])
    let timeout = int32(parsetoml.getInt(machine["timeout"]))
    
    let buffer_len = parsetoml.getInt(machine["buffer_len"])
    
    let port = newSerialPort(portName)
    
    ## redis
    let init_fn = parsetoml.getStr(config["redis"]["init_lua"],"init.lua")    
    var fs2 = newFileStream(init_fn, fmRead)    
    let init_script = fs2.readAll()
    
    let lua_fn = parsetoml.getStr(config["redis"]["enqueue_lua"],"enqueue.lua")    
    var fs = newFileStream(lua_fn, fmRead)    
    let lua_script = fs.readAll()    
    
    var sha1:string    
    
    let rdb = newRedisDB(config["redis"])
    if rdb.enable:
        let rtn = rdb.exec("EVAL", @[init_script, "0"])
        ##  # load lua script
        sha1 = rdb.exec("SCRIPT", @["LOAD", lua_script])     
    
    ## open Serial Port
    port.open(baud_rate, Parity(parity), byteSize, 
              StopBits(stopBits), readTimeout = timeout)
    
    var receiveBuffer = newString(buffer_len)
    
    var numReceived:int
    
    while true:
        #let rtn = port.write("abc")
        #echo rtn
        ##  createdon = format(now(),"yyyy-MM-dd'T'HH:mm:ss")
        try:
            ## read
            numReceived = port.read(receiveBuffer)
        except TimeoutError:
            echo "timeout"
            sleep(100)
            continue
        except:
            echo "error"
            sleep(100)
            continue
      
        let data_str = receiveBuffer[0 ..< numReceived]

        echo getClockStr() & "," &  receiveBuffer[0 ..< numReceived]

        let ts = epochTime().formatFloat(ffDecimal, 4)

        let eval_rtn = rdb.exec("EVALSHA", @[sha1, "1", "ws", ts, receiveBuffer[0 ..< numReceived]])
        echo eval_rtn
        ## write
        discard port.write(receiveBuffer[0 ..< numReceived])
        ## sleep in ms
        sleep(INTERVAL)
    
    #port.close()

when isMainModule:
    
    main()