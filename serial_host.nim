
import os
import serial # Or: `import serial/utils`
import times

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
    
    let portName = parsetoml.getStr(machine["port"])
    let baud_rate = int32(parsetoml.getInt(machine["baudRate"]))
    let dataBits = byte(parsetoml.getInt(machine["dataBits"]))
    let parity = parsetoml.getInt(machine["parity"])
    let stopBits = parsetoml.getInt(machine["stopBits"])
    let timeout = int32(parsetoml.getInt(machine["timeout"]))
    
    let buffer_len = parsetoml.getInt(machine["buffer_len"])
    
    let msg = parsetoml.getStr(machine["msg"])

    get_ports()

    let port = newSerialPort(portName)
    
    ## open Serial Port
    port.open(baud_rate, Parity(parity), dataBits, 
              StopBits(stopBits), readTimeout = timeout)

    var receiveBuffer = newString(1024)
    while true:
        
      #var msg:string = "M1T X+12.68mm Y-15.79mm Z+25.68mm\r\n"
      let rtn = port.write(msg)
      #echo rtn
      let numReceived = port.read(receiveBuffer)
      echo getClockStr() & "," & receiveBuffer[0 ..< numReceived]
      #discard port.write(receiveBuffer[0 ..< numReceived])
      sleep(1000)


when isMainModule:
    
    main()