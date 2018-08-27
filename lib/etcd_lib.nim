
# etcd_lib.nim

##
##  etcd client
##  heartbeat
##  get config from etcd
##


import os
import json
import times

import etcd_client
import parsetoml

const hb_base = "heartbeat/"

type 
    DBClient* = ref object of RootObj
        config: TomlValueRef
        client: EtcdClient

proc newDBClient*(config: TomlValueRef): DBClient = 
    
    let hostname = parsetoml.getStr(config["hostname"])
    let port = parsetoml.getInt(config["port"])
    let username = parsetoml.getStr(config["username"])
    let password = parsetoml.getStr(config["password"])
    
    let client = new_etcd_client(hostname=hostname, port=port, 
                                 username=username, password=password, failover=false)
    
    return DBClient(config:config, client: client)
    
proc reconnect*(self:DBClient):void = 
    
    let hostname = parsetoml.getStr(self.config["hostname"])
    let port = parsetoml.getInt(self.config["port"])
    let username = parsetoml.getStr(self.config["username"])
    let password = parsetoml.getStr(self.config["password"])
    
    let client = new_etcd_client(hostname=hostname, port=port, 
                                 username=username, password=password, failover=false)

proc heartbeat*(self:DBClient, path:string):string = 

    let t = format(now(), "YYYY-MM-dd'T'HH:mm:ss")

    self.client.set(hb_base & path, t) # or update
    
    return t


proc test(config: TomlValueRef):void = 

    let db: DBClient = newDBClient(config)
    
    let path = "heartbeat/eqpt01"
    
    discard db.heartbeat(path)
    
    sleep(6000)
    
    db.reconnect()
    
    discard db.heartbeat(path)    
    
    
when isMainModule:

    var config = parsetoml.parseString("""
[etcd]
hostname = "127.0.0.1"
port = 2379
username = ""
password = ""  """)

    test(config["etcd"])
    
    