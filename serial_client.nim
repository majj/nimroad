
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
    let port = newSerialPort("COM6")
    ##  Parity:,    ##  None = 0,    ##  Odd = 1,    ##  Even = 2,    
    ##  StopBits:    ##  One = 1,    ##  Two = 2,    ##  OnePointFive = 3    
    port.open(9600, Parity(1), 8, StopBits(1))
    var receiveBuffer = newString(1024)
    while true:
      #let rtn = port.write("abc")
      #echo rtn  
      let numReceived = port.read(receiveBuffer)
      echo getClockStr() & "," & receiveBuffer[0 ..< numReceived]
      discard port.write(receiveBuffer[0 ..< numReceived])
      sleep(1000)
    
    port.close()

when isMainModule:
    
    main()