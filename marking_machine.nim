
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
    
    info(port_list.join(sep=","))
    
    ## rs232
    let machine = config["machine"]
    
    let portName = parsetoml.getStr(machine["port"])
    let baud_rate = parsetoml.getInt(machine["baudRate"])
    let dataBits = parsetoml.getInt(machine["dataBits"])
    let parity = parsetoml.getInt(machine["parity"])
    let stopBits = parsetoml.getInt(machine["stopBits"])
    
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
    port.open(int32(baud_rate), Parity(parity), byte(dataBits), 
              StopBits(stopBits), readTimeout = 1000)
    
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

        var rtn2 = rdb.exec("EVALSHA", @[sha1, "1", "ws", ts, receiveBuffer[0 ..< numReceived]])
        echo "return: " & rtn2
        ## write
        discard port.write(receiveBuffer[0 ..< numReceived])

        sleep(1000)
    
    #port.close()

when isMainModule:
    
    main()