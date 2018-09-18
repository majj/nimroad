
##
##  
##  get data from redis (msgpack, json)
##  
##  send data to influxdb(cluster)
##  
##  if sink failed then save data to sqlite (retry queue)
##  when send failed,send alert(smtp)
##  when failed then ping influxdb.
##

# =======
# Imports
# =======
import os
import strutils
import times
import asyncdispatch
import json
import tables
import typetraits

import parsetoml
import redis

import lib.logging
import lib.etcd_lib
import lib.utils


let hApp = newHApp()
let config = hApp.config
# echo toTomlString(config["app"])
# get array from toml
let influxdb_conf =  getElems(config["influxdb"])

type
    Chitu = ref object of RootObj
        
        config: TomlValueRef
        
        schema: Table[string, string]  # measurement, table
        
        quene_len_redis: int # redis
        quene_len_sqlite: int # 

proc newChitu(config: TomlValueRef): Chitu = 

    return Chitu(config: config)
       
proc get_data_from_redis(self: Chitu): seq[JsonNode] = 
    let v1: JsonNode = %* {"measurement":"mts", "tags":{"eqptno":"mts02"}, 
                           "fields":{"val1":"2i","val2":"3.3","val3":"i"}, "time":100}
                           
    let v2: JsonNode = %* {"measurement":"mts", "tags":{"eqptno":"mts02"}, 
                           "fields":{"val1":"2i","val2":"3.3","val3":"i"}, "time":200}
    
    result.add(v1)    
    result.add(v2)

proc get_data(self: Chitu): seq[JsonNode] = 

    let v1: JsonNode = %* {"measurement":"mts", "tags":{"eqptno":"mts02"}, 
                           "fields":{"val1":"2i","val2":"3.3","val3":"i"}, "time":100}
                           
    let v2: JsonNode = %* {"measurement":"mts2", "tags":{"eqptno":"mts02"}, 
                           "fields":{"val1":"2i","val2":"3.3","val3":"i"}, "time":200}
                           
    let v3: JsonNode = %* {"measurement":"mts", "tags":{"eqptno":"mts02"}, 
                           "fields":{"val1":"2i","val2":"3.3","val3":"i"}, "time":200}
                           
    echo v2["measurement"]
    
    result.add(v1)    
    result.add(v2)
    result.add(v3)

proc sink(self: Chitu, data: seq[JsonNode]): seq[string] = 
    # send to influxdb
    
    if len(data) > 0:
        echo ">0"
    else:
        warn("PING")
        
    var data_table: Table[string, seq[JsonNode]]
    
    #var data_group: seq[JsonNode]
        
    for item in data:
        let measurement = getStr(item["measurement"]) # get m from json
        echo item
        data_table[measurement].add(item)
        #echo("$1$2$3.yaml".format("conf", sep, measurement))
        
    echo data_table
    
    for db_conf in influxdb_conf:
        
        echo db_conf        
        
        result.add(parsetoml.getStr(db_conf["host"]))
    
    echo join(result, "|")

proc dequeue(self: Chitu):seq[JsonNode] = 

    let v1: JsonNode = %* {"data":{"measurement":"mts", "tags":{"eqptno":"mts02"}, 
                                   "fields":{"val1":"2i","val2":"3.3","val3":"i"}, "time":200},
                            "status":"127.0.0.1|127.0.0.1"}
    
    result.add(v1)       

proc enqueue(self: Chitu, data: seq[JsonNode], status: seq[string]):void = 
    # sqlite
    # insert
    
    # update
    
    echo data, status


proc main():void = 
    
    info("start chitu")
    
    let chitu: Chitu = newChitu(config)

    let etcd: DBClient = newDBClient(config["etcd"])
    
    let path = "eqpt01"
    
    var hb_timer:float = epochTime()

    while true:
        
        try:
            
            let data = chitu.get_data()
            
            let data_len: int = len(data)
            
            if data_len > 0:
                
                let status: seq[string] = chitu.sink(data)
            
                if len(status)>0:
                    
                    chitu.enqueue(data, status)
                    
                sleep(1000) # sleep 1s
            else:
                sleep(10) # sleep 10ms
                
            let t2 = epochTime()
            
            if t2 - hb_timer > 3:
                # set heartbeat every 30s
                
                let ts = etcd.heartbeat(path)
                info("heartbeat sent")
                # set heartbeat timer
                hb_timer = t2                  
            
        except:

            let
                e = getCurrentException()
                msg = getCurrentExceptionMsg()
            error( "Got exception " & repr(e) & " with message " & msg)
    
# run main
if isMainModule:
    main()
