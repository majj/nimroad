## serial_T.nim
##
## 
##  COM1 --------------- COM2
##       ------/ \------  
##             | |
##             | |
##            Redis
##

import 
    asyncdispatch,
    os,
    strutils,
    streams,
    times

import 
    serial, # Or: `import serial/utils`
    parsetoml

import
    lib/db_redis,
    lib/logging,
    lib/utils


let hApp = newHApp()
let config = hApp.config

proc get_ports() = 

    var port_list:seq[string]
    
    for port in listSerialPorts():
      ##  echo port
      port_list.add(port)
      
    debug(port_list.join(sep=";"))
      
proc main() = 
    
    info("start T...")
    
    let INTERVAL = parsetoml.getInt(config["app"]["interval"])
    let workstation = parsetoml.getStr(config["app"]["ws"])
    
    ## rs232
    let machine = config["machine"]
    
    let portName1 = parsetoml.getStr(machine["port_upper"])
    let portName2 = parsetoml.getStr(machine["port_machine"])
    
    let baud_rate = int32(parsetoml.getInt(machine["baudRate"]))
    let byteSize = byte(parsetoml.getInt(machine["byteSize"]))
    let parity = parsetoml.getInt(machine["parity"])
    let stopBits = parsetoml.getInt(machine["stopBits"])
    let timeout = int32(parsetoml.getInt(machine["timeout"]))
    
    let buffer_len = parsetoml.getInt(machine["buffer_len"])
    
    let msg = parsetoml.getStr(machine["msg"])

    get_ports()

    ## open two ports
    let port1 = newSerialPort(portName1)  # upper computer
    let port2 = newSerialPort(portName2)  # machine
    
    ## open Serial Port1
    port1.open(baud_rate, Parity(parity), byteSize, 
              StopBits(stopBits), readTimeout = timeout)
    ## open Serial Port2
    port2.open(baud_rate, Parity(parity), byteSize, 
              StopBits(stopBits), readTimeout = timeout)
              
              
    var receiveBuffer1 = newString(1024)
    var receiveBuffer2 = newString(1024)
    
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
    
    while true:
        
        #var msg:string = "M1T X+12.68mm Y-15.79mm Z+25.68mm\r\n"
        try:
            
            #echo rtn
            let numReceived1 = port1.read(receiveBuffer1)
            if numReceived1 > 0:
                ## upper computer to machine
                debug( portName1 & " -> " &  getClockStr() & "," & receiveBuffer1[0 ..< numReceived1] )
                discard port2.write(receiveBuffer1[0 ..< numReceived1])

            let numReceived2 = port2.read(receiveBuffer2)
            if numReceived2 > 0:
                ## machine to upper computer
                debug( portName2 & " -> " & getClockStr() & "," & receiveBuffer2[0 ..< numReceived2] )
                discard port1.write(receiveBuffer2[0 ..< numReceived2])
                
                let ts = epochTime().formatFloat(ffDecimal, 4)

                let eval_rtn = rdb.exec("EVALSHA", @[sha1, "1", workstation, ts, receiveBuffer2[0 ..< numReceived2]])
                debug( eval_rtn )
                
            ## loop interval
            sleep(INTERVAL)            
            
        except TimeoutError:            
            let msg = getCurrentExceptionMsg()
            warn(msg)
            sleep(1000)            
        except:            
            warn( getCurrentException().name )
            let msg = getCurrentExceptionMsg()
            error(msg)
            sleep(1000)

when isMainModule:
    
    main()