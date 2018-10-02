
import time
import json

import redis
import serial
import serial.tools.list_ports

REDIS_HOST = 'localhost'
REDIS_PORT = 6379

PORT = "COM8"
BAUDRATE = 9600
BYTESIZE = 8
PARITY = serial.PARITY_ODD
STOPBITS = 1

INTERVAL = 0.6

MSG = b"M1T X+12.68mm Y+15.79mm Z+25.68mm\r\n"

def main():
    
    plist = list(serial.tools.list_ports.comports())
    print("RS232 Ports: ", end="")
    for p in plist:
        print(p[0], end=",")
    print()

    ## redis client
    red = redis.StrictRedis(host=REDIS_HOST, port=REDIS_PORT, db=0)
    
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
    
    ## open serial port
    port = serial.Serial(port=PORT, baudrate=BAUDRATE, bytesize=BYTESIZE, 
                         parity=PARITY, stopbits=STOPBITS, timeout=0)
    ## loop here
    while True:
        ## read msg from serial port
        msg = port.readall()
        
        if msg != b'':
            print(msg)            

            y = multiply(keys=['MTS01'], args=[time.time(), msg])
            
            print(y)
            
            port.write(MSG)
        
        else:
            print("no data")
            port.write(MSG)
            
        time.sleep(INTERVAL)
   
if __name__ == "__main__"    :
    
    main()