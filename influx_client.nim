

##  SHOW FIELD KEYS FROM "eim"."autogen"."nt2"

import random
import os
import json
import strutils
import times
import tables

import lib.influx

proc test_influx():void = 
    # parameters for influxdb
    let protocol = ConnectionProtocol.HTTP
    let host = "127.0.0.1"
    let port = 8086
    let username = "root"
    let password = "root"

    var db = InfluxDB(protocol: protocol, host:host, port:port, username:username, password:password)

    # json to table?

    # datatype
    
    echo db.getVersion()
    echo ">>"
    echo "query:", db.query("eim","""select max(i) from nt3 """)
    echo ">>>"
    
    
    let data_dict = {"i":"int", "j":"str","k":"float"}.toTable

    var line:LineProtocol

    var i:int = 0

    while true:
        
        i = i + 1
        
        let data = {"i": intToStr(911 + random(100) ),
                    "j":"eqpt3",
                    "k": (float(i) + 0.3726).formatFloat(ffDecimal, 4)}.toTable
                    
        let tags = {"machine":"mts02"}.toTable
        
        line = LineProtocol(measurement: "nt3",timestamp: int64(1000_000_000 * epochTime()), tags:tags, fields:data)

        let a = influx.write(db, "eim", @[line], data_dict)
        
        echo(a)
        
        #  SHOW FIELD KEYS FROM "eim"."autogen"."nt2"
        
        let b = influx.query(db, "eim", "select last(*) from nt3 ")
        
        echo($(b[1]))
        
        sleep(2000)
   
if isMainModule:
    
    test_influx()
    