
import os
import serial # Or: `import serial/utils`
import times

proc get_ports() = 

    var port_list:seq[string]
    
    for port in listSerialPorts():
      ##  echo port
      port_list.add(port)
      
    echo port_list
      
proc main() = 

    get_ports()

    let port = newSerialPort("COM5")
    
    port.open(9600, Parity(1), 8, StopBits(1))

    var receiveBuffer = newString(1024)
    while true:
        
      var msg:string = "M1T X+12.68mm Y-15.79mm Z+25.68mm\r\n"
      let rtn = port.write(msg)
      echo rtn  
      let numReceived = port.read(receiveBuffer)
      echo getClockStr() & "," & receiveBuffer[0 ..< numReceived]
      #discard port.write(receiveBuffer[0 ..< numReceived])
      sleep(1000)


when isMainModule:
    
    main()