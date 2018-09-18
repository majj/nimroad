
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
        #config: TomlValueRef
        target: string
        db: DbConn
        #status: int

proc newDataQueue(dbfile:string): DataQueue = 
    # new(ref) or init(val)? 
    #self.db =  open("data_queue.db", nil, nil, nil)
    #echo self.config
    
    let db=open(dbfile, nil, nil, nil)
    
    let status=1
    
    let self = DataQueue(db:db)
    
    self.db.exec(sql"PRAGMA SYNCHRONOUS = OFF")

    self.db.exec(sql"DROP TABLE IF EXISTS JOB_QUEUE")

    self.db.exec(sql"VACUUM")

    self.db.exec(sql("""CREATE TABLE IF NOT EXISTS JOB_QUEUE (
         ID    INTEGER PRIMARY KEY,
         Status         INT(11),
         Host           VARCHAR(64),
         Parameters     VARCHAR(2000),
         Info           VARCHAR(1000),  
         RetryTimes     INT(11),
         Active         INT(11),
         CreatedOn      datetime,
         CreatedBy      VARCHAR(50),
         LastUpdateOn   datetime
         )"""))
    return self
  
proc enqueue(self: DataQueue, host:string, data:seq[JsonNode]): void = 

    echo "enqueue"
    # begin transaction
    self.db.exec(sql"BEGIN")
    for json_data in data:
        self.db.exec(sql"""INSERT INTO JOB_QUEUE (Status, Host, Parameters, RetryTimes, Active, CreatedOn) 
                        VALUES (?,?,?,0,1,datetime('now'))""",
            1, host, $json_data) # $v json to string
        #transaction end
    self.db.exec(sql"COMMIT")
    
proc update(self: DataQueue, ids:seq[int]):void =
    echo join(ids, sep=",")
    #sql"update DATA_QUEUE set status=?, where id = ?"
    #sql"update DATA_QUEUE set status=?, Hosts=? where id = ?"
    #sql"delete from DATA_QUEUE where id = ?"

proc dequeue(self: DataQueue, info_s: string): void = 
    echo "dequeue:", info_s
    
    #self.db.exec(sql"Drop table if exists data_queue")

    self.db.exec(sql"VACUUM")    

proc queue_t(self: DataQueue): void = 
    
    self.db.exec(sql"BEGIN")
    
    for row in self.db.fastRows(sql"""select ID, Status, Host, Parameters, 
        RetryTimes from JOB_QUEUE where Status>0 and Active = 1 and RetryTimes < 6 """):
        
        echo row
        var status = parseInt(row[1])
        var retry_times = parseInt(row[4])
        let json_data = parseJson(row[3])
        
        retry_times = retry_times + 1
        
        self.db.exec(sql"""update JOB_QUEUE set Info = ?, 
                    RetryTimes=RetryTimes+1, LastUpdateOn=datetime('now') where ID=?""",
                    "test",  row[0])
    self.db.exec(sql"COMMIT")
    
    for row in self.db.fastRows(sql"""select ID, Status, Host, Parameters, 
        RetryTimes   from JOB_QUEUE where Status>0 and Active = 1 and RetryTimes < 6 """):
        echo row
        #self.db.exec(sql"""delete from JOB_QUEUE where ID=?""",row[0])
        #self.db.exec(sql"VACUUM")
        ##  if row[1] in [1,3] :
            ##  #send1("P")
            ##  status = status + send1("P")            
        ##  if row[1] in [2,3]:
            ##  #send0("S")
            ##  status = status + 2 * send0("P")
        ##  echo "update $1", status
        #echo data_j
        #echo "$1,$2,$3".format(row[0], getStr(data_j["a"]), row[2])
    
    #self.update(@[1,2,3],@["a","b"])
    ##  let id = self.db.tryInsertId(sql"INSERT INTO data_queue (name, active, val) VALUES (?,?,?)",
          ##  "Item#1001", 1001, sqrt(1001.0))
          
    ##  echo "Inserted item: ", self.db.getValue(sql"SELECT name FROM data_queue WHERE id=?", id)

proc main(config: TomlValueRef): void = 

    #let dataQ = DataQueue(db:open("data_queue.db", nil, nil, nil), status:1, config:config)
    let dataQ: DataQueue = newDataQueue("host1.db")
    
    let t = "n-$1".format(1)
    # convert to JsonNode 
    let json_data = %* {"a":t}
    
    let host = "host2"  
    
    dataQ.enqueue(host, @[json_data, json_data, json_data])
    
    dataQ.dequeue("iot")
    
    try:
        dataQ.queue_t()
    except:
        let e = getCurrentException()
        let msg = getCurrentExceptionMsg()
        echo msg
    #dataQ.db.exec(sql"COMMIT")
    dataQ.db.close()
    
when isMainModule:
    let config = get_config("conf/watchman.toml")
    main(config)