
##
## sqlite as data queue
## move data from memory(redis) to file system.
##

import os
import math
import json

import strutils
import typetraits

import db_sqlite
import parsetoml

import lib.utils

type DataQueue = ref object of RootObj
    config:TomlValueRef
    db: DbConn
    status: int

method  init(this:DataQueue):void {.base.} = 
    # new(ref) or init(val)? 
    #this.db =  open("data_queue.db", nil, nil, nil)
    #echo this.config
    
    this.db.exec(sql"PRAGMA synchronous = OFF")

    this.db.exec(sql"Drop table if exists data_queue")

    this.db.exec(sql"VACUUM")

    this.db.exec(sql("""create table data_queue (
         id    INTEGER PRIMARY KEY,
         name  VARCHAR(50) NOT NULL,
         active     INT(11),
         val     DECIMAL(18,10),
         data    VARCHAR(1000),
         dt      datetime
         )"""))
    #return this
  
method enqueue(this:DataQueue):void {.base.} = 
    echo "enqueue"
    # begin transaction
    this.db.exec(sql"BEGIN")
    
    for i in 1..10:
      # call prepare_v2 inside
      let t = "n$1".format(i)
      # convert to JsonNode 
      let v = %* {"a":t}
      this.db.exec(sql"INSERT INTO data_queue (name, active, val, data, dt) VALUES (?,?,?,?,datetime('now'))",
            "Item#" & $i, 1, sqrt(i.float),$v) # $v json to string
    
    #transaction end
    this.db.exec(sql"COMMIT")
    
method dequeue(this:DataQueue, info_s:string):void {.base.} = 
    echo "dequeue:", info_s
    
    #this.db.exec(sql"Drop table if exists data_queue")

    this.db.exec(sql"VACUUM")    

method queue_t(this:DataQueue):void {.base.} = 

    for row in this.db.fastRows(sql"select * from data_queue"):
        
        let data_j = parseJson(row[4])
        echo "$1,$2,$3".format(row[0], getStr(data_j["a"]), row[5])

    let id = this.db.tryInsertId(sql"INSERT INTO data_queue (name, active, val) VALUES (?,?,?)",
          "Item#1001", 1001, sqrt(1001.0))
          
    echo "Inserted item: ", this.db.getValue(sql"SELECT name FROM data_queue WHERE id=?", id)

proc main(config:TomlValueRef):void = 

    
    let dataQ = DataQueue(db:open("data_queue.db", nil, nil, nil), status:1, config:config)
    
    dataQ.init()
    
    dataQ.enqueue()
    
    dataQ.dequeue("iot")
    
    dataQ.queue_t()
    
    dataQ.db.close()
    
when isMainModule:
    
    let config = get_config("conf/watchman.toml")

    main(config)