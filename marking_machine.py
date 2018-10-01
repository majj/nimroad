
import time
import json

import redis
import serial
import serial.tools.list_ports

PORT = "COM6"
BAUDRATE = 9600

def main():
    
    plist = list(serial.tools.list_ports.comports())    
    for p in plist:
        print(p[0])

    ## redis client
    red = redis.StrictRedis(host='localhost', port=6379, db=0)
    
    ## init script
    with open("conf/marking_machine_init.lua","r") as fh:
        lua_init = fh.read()    
    
    init_data = red.register_script(lua_init)
    r = init_data(keys=[], args=[])
    #print(y)
    
    ## enqueue script
    with open("conf/marking_machine_enqueue.lua","r") as fh2:
        lua = fh2.read()
    #print(lua)
    multiply = red.register_script(lua)
    
    timestamp = 1234456777
    
    ## open serial port
    port = serial.Serial(port=PORT, baudrate=BAUDRATE, bytesize=8, 
                         parity=serial.PARITY_ODD, stopbits=1, timeout=0)
    ## loop
    while True:
        ## read msg from serial port
        msg = port.readall()
        
        if msg != b'':
            print(msg)            

            y = multiply(keys=['MTS01'], args=[time.time(), msg])
            
            print(y)
            
            port.write(b"M1T X+12.68mm Y+15.79mm Z+25.68mm\r\n")
        
        else:
            port.write(b"M1T X+12.68mm Y-25.79mm Z+25.68mm\r\n")
            
        time.sleep(0.6)
   
if __name__ == "__main__"    :
    
    main()