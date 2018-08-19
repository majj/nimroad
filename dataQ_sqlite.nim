
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

type 
    
    DataQueue = ref object of RootObj
        # ref
        # Signlton ?
        config: TomlValueRef
        db: DbConn
        status: int

proc  newDataQueue(config: TomlValueRef): DataQueue = 
    # new(ref) or init(val)? 
    #self.db =  open("data_queue.db", nil, nil, nil)
    #echo self.config
    
    let db=open("data_queue.db", nil, nil, nil)
    let status=1
    
    let self = DataQueue(db:db, status:status, config:config)
    
    self.db.exec(sql"PRAGMA synchronous = OFF")

    self.db.exec(sql"Drop table if exists data_queue")

    self.db.exec(sql"VACUUM")

    self.db.exec(sql("""create table data_queue (
         id    INTEGER PRIMARY KEY,
         name  VARCHAR(50) NOT NULL,
         active     INT(11),
         val     DECIMAL(18,10),
         data    VARCHAR(1000),
         dt      datetime
         )"""))
    return self
  
method enqueue(self: DataQueue): void {.base.} = 
    echo "enqueue"
    # begin transaction
    self.db.exec(sql"BEGIN")
    
    for i in 1..10:
      # call prepare_v2 inside
      let t = "n$1".format(i)
      # convert to JsonNode 
      let v = %* {"a":t}
      self.db.exec(sql"INSERT INTO data_queue (name, active, val, data, dt) VALUES (?,?,?,?,datetime('now'))",
            "Item#" & $i, 1, sqrt(i.float),$v) # $v json to string
    
    #transaction end
    self.db.exec(sql"COMMIT")
    
method dequeue(self: DataQueue, info_s: string): void {.base.} = 
    echo "dequeue:", info_s
    
    #self.db.exec(sql"Drop table if exists data_queue")

    self.db.exec(sql"VACUUM")    

method queue_t(self: DataQueue): void {.base.} = 

    for row in self.db.fastRows(sql"select * from data_queue"):
        
        let data_j = parseJson(row[4])
        echo "$1,$2,$3".format(row[0], getStr(data_j["a"]), row[5])

    let id = self.db.tryInsertId(sql"INSERT INTO data_queue (name, active, val) VALUES (?,?,?)",
          "Item#1001", 1001, sqrt(1001.0))
          
    echo "Inserted item: ", self.db.getValue(sql"SELECT name FROM data_queue WHERE id=?", id)

proc main(config: TomlValueRef): void = 

    
    #let dataQ = DataQueue(db:open("data_queue.db", nil, nil, nil), status:1, config:config)
    
    let dataQ: DataQueue = newDataQueue(config)
    
    dataQ.enqueue()
    
    dataQ.dequeue("iot")
    
    dataQ.queue_t()
    
    dataQ.db.close()
    
when isMainModule:
    
    let config = get_config("conf/watchman.toml")

    main(config)