
import os
import serial # Or: `import serial/utils`
import times

import asyncdispatch 

import parsetoml

import lib/logging
import lib/utils

let hApp = newHApp()
let config = hApp.config

proc get_ports() = 

    var port_list:seq[string]
    
    for port in listSerialPorts():
      ##  echo port
      port_list.add(port)
      
    echo port_list
      
proc main() = 

    ## rs232
    let machine = config["machine"]
    
    let portName1 = parsetoml.getStr(machine["port1"])
    let portName2 = parsetoml.getStr(machine["port2"])
    
    let baud_rate = int32(parsetoml.getInt(machine["baudRate"]))
    let byteSize = byte(parsetoml.getInt(machine["byteSize"]))
    let parity = parsetoml.getInt(machine["parity"])
    let stopBits = parsetoml.getInt(machine["stopBits"])
    let timeout = int32(parsetoml.getInt(machine["timeout"]))
    
    let buffer_len = parsetoml.getInt(machine["buffer_len"])
    
    let msg = parsetoml.getStr(machine["msg"])

    get_ports()

    let port1 = newSerialPort(portName1)
    let port2 = newSerialPort(portName2)
    
    ## open Serial Port
    port1.open(baud_rate, Parity(parity), byteSize, 
              StopBits(stopBits), readTimeout = timeout)

    port2.open(baud_rate, Parity(parity), byteSize, 
              StopBits(stopBits), readTimeout = timeout)
              
              
    var receiveBuffer1 = newString(1024)
    var receiveBuffer2 = newString(1024)
    
    while true:
        
        #var msg:string = "M1T X+12.68mm Y-15.79mm Z+25.68mm\r\n"
        try:
            
            #echo rtn
            let numReceived1 = port1.read(receiveBuffer1)
            if numReceived1 > 0:
                echo portName1 & " -> " &  getClockStr() & "," & receiveBuffer1[0 ..< numReceived1]
                discard port2.write(receiveBuffer1[0 ..< numReceived1])

            let numReceived2 = port2.read(receiveBuffer2)
            if numReceived2 > 0:
                echo portName2 & " -> " & getClockStr() & "," & receiveBuffer2[0 ..< numReceived2]
                discard port1.write(receiveBuffer2[0 ..< numReceived2])
                
                
            sleep(10)            
            
        except:
            let msg = getCurrentExceptionMsg()
            echo(msg)
            sleep(1000)


when isMainModule:
    
    main()