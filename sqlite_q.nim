
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

let dataq_db = open("data_queue.db", nil, nil, nil)

proc init():void = 

    dataq_db.exec(sql"PRAGMA synchronous = OFF")

    dataq_db.exec(sql"Drop table if exists data_queue")

    dataq_db.exec(sql"VACUUM")

    dataq_db.exec(sql("""create table data_queue (
         id    INTEGER PRIMARY KEY,
         name  VARCHAR(50) NOT NULL,
         active     INT(11),
         val     DECIMAL(18,10),
         data    VARCHAR(1000),
         dt      datetime
         )"""))
         
proc enqueue():void = 
    echo "enqueue"
    # begin transaction
    dataq_db.exec(sql"BEGIN")
    
    for i in 1..10:
      # call prepare_v2 inside
      let t = "n$1".format(i)
      # convert to JsonNode 
      let v = %* {"a":t}
      dataq_db.exec(sql"INSERT INTO data_queue (name, active, val, data, dt) VALUES (?,?,?,?,datetime('now'))",
            "Item#" & $i, 1, sqrt(i.float),$v) # $v json to string
    
    #transaction end
    dataq_db.exec(sql"COMMIT")
    
proc dequeue():void = 
    echo "dequeue"    

proc queue_t():void = 

    init()

    enqueue()

    for row in dataq_db.fastRows(sql"select * from data_queue"):
        
        let data_j = parseJson(row[4])
        echo "$1,$2,$3".format(row[0], getStr(data_j["a"]), row[5])

    let id = dataq_db.tryInsertId(sql"INSERT INTO data_queue (name, active, val) VALUES (?,?,?)",
          "Item#1001", 1001, sqrt(1001.0))
          
    echo "Inserted item: ", dataq_db.getValue(sql"SELECT name FROM data_queue WHERE id=?", id)

    dataq_db.close()
    
when isMainModule:
    queue_t()