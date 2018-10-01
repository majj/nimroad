
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
    port.close()
    # use 9600bps, no parity, 8 data bits and 1 stop bit
    port.open(9600, Parity.None, 8, StopBits.One)

    # You can modify the baud rate, parity, databits, etc. after opening the port
    ##  port.baudRate = 2400

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