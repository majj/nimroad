# -*- coding: utf-8 -*-

# http://www.binarytides.com/python-socket-server-code-example/
"""
simulator for AK Server(BIW)
"""

import socket
import sys
import traceback

import _thread
#from thread import *

import struct

import logbook
#import gevent

from time import strftime, localtime

class Log(object):
    
    def __init__(self):
        pass

    def info(self, msg):
        print(msg)

    def debug(self, msg):
        print(msg)
        
    def error(self, msg):
        print(msg)

log = Log()

# static
STX = 0x02
ETX = 0x03
BLANK = 0x20 # 

ak_data = {'ASTZ': 'SMAN STBY N/A  SVOR ???? N/A ', 'ATCO': 'NA', 'ARAL': 'ARAL', 'AFOF': '0.0000', 'ABRP': '  0.0', 'AMST': 'SFRT', 'AKON': '0.0 0.0 0.0 0.9023 0.0 0.0 0.0', 'AAUG': '0 10000.0  440.0  0.450', 'ATHP': ' -nan', 'AVFI': '  0.0   -0.5', 'AWBP': '158.6', 'ADEF': 'NA', 'ARBT': 'IDLE', 'AREF': 'LF', 'AVMA': '100.0', 'AFAN': '0.0', 'ASTF': '1000001,5002', 'AFWD': 'S2WD', 'AGST': '0.0000', 'AWRT': '0.0 0.0 0.000 0 STBY 0.000 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0', 'ARLP': '1.45 0.74 30.39 87.60 7150.00 -0.050000 20.00 0.30 0.00 -1500.00 1.00 1.00 1.00 27.60 1.00 5.00 6.00 95.00 0.000000 0.000000 0.158100 4.000 18.00 8.00', 'ADRV': 'STOP', 'AWEG': '    0.9023', 'ASIE': '26.2734 0.14186 0.017526 0.0000000 11.6856 0.26959 -0.001714 0.0000000 2810.9'}

def pack(cmd):    
    """ pack """
    
    clen = len(cmd)
    
    dt = strftime("%Y-%m-%d %H:%M:%S", localtime())
    
    if cmd == "ASTF":
        
        fmt = "!2b%ds3b" % (clen)    
        # 0x48:'0'
        buf = struct.pack(fmt, STX, BLANK, cmd, BLANK, 0x30, ETX)         
    
    else:
        #data = " SMAN STBY SLIR SVOR SBEI N/A "
        data = ak_data[cmd]
        dlen = len(data)
        
        fmt = "!2b%ds3b%ds1b" % (clen, dlen)
    
        # 0x48:'0'
        buf = struct.pack(fmt, STX, BLANK, cmd, BLANK, 0x48, BLANK, data, ETX) 
    
    log.debug(buf)
    
    return buf

def clientthread(conn):    
    """ client thread """
    
    try:
        while True:
             
            #Receiving from client
            
            
            
            idata = conn.recv(1024)
            log.debug("recv")
            
            dlen = len(idata) - 11
            
            #print dlen
            
            if dlen > 0:   
                fmt = "!2b4s4b%ds1d" % (dlen)
                
            else:
                fmt = "!2b4s5b"
                
            #val = struct.unpack(fmt, idata)
            
            timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime())
            
            #print("[%s] %s" %(timestamp, val))
            
            log.debug(idata)
            
            if not idata: 
                break
                
            #buf = pack(val[2])
            buf = data = b'\x02\x02\x06\x06\x07\x07\x07\x07\x08\x08\x08\x08\x08\x00\x00\x01\x01\x00\x00\x01\x01\x00\x00\x01\x01\x00\x00\x01\x01\x00\x00\x01\x01\x00\x00\x01\x01\x00\x00\x01\x01\x00\x00\x01\x01\x00\x00\x01\x01\x03'
            conn.sendall(buf)
         
        #came out of loop
        conn.close()
    except Exception as ex:
        log.debug(ex)
        log.debug(traceback.print_exc())
        #print("client closed")
        #raise



def server(): 
    
    """ server """

    host = "127.0.0.1"
    
    port = 9527
     
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    
    log.debug('Socket created %s:%s' % (host, port) )
     
    #Bind socket to local host and port
    try:
        sock.bind((host, port))
        
    except socket.error as msg:
        
        log.debug('Bind failed. Error Code : ' + str(msg[0]) + ' Message ' + msg[1] )
        sys.exit()
         
    log.debug('Socket bind complete')
     
    #Start listening on socket
    sock.listen(10)
    log.debug('Socket now listening')
     
    #Function for handling connections. This will be used to create threads

    #now keep talking with the client  

    
    while 1:
        #wait to accept a connection - blocking call
        conn, addr = sock.accept()
        log.debug( 'Connected with ' + addr[0] + ':' + str(addr[1]) )
         
        # start new thread takes 1st argument as a function name to be run, 
        # second is the tuple of arguments to the function.
        _thread.start_new_thread(clientthread ,(conn,))
    
    sock.close()
        
def main():
    """ main """
    server()
    
if __name__ == "__main__":
    
    main()