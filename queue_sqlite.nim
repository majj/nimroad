


import db_sqlite, math

proc test():void = 

    let dataq_db = open("data_queue.db", nil, nil, nil)

    dataq_db.exec(sql"Drop table if exists data_queue")

    dataq_db.exec(sql"VACUUM")

    dataq_db.exec(sql("""create table data_queue (
         Id    INTEGER PRIMARY KEY,
         Name  VARCHAR(50) NOT NULL,
         i     INT(11),
         f     DECIMAL(18,10))"""))

    dataq_db.exec(sql"BEGIN")
    for i in 1..10:
      dataq_db.exec(sql"INSERT INTO data_queue (name,i,f) VALUES (?,?,?)",
            "Item#" & $i, i, sqrt(i.float))
    dataq_db.exec(sql"COMMIT")

    for x in dataq_db.fastRows(sql"select * from data_queue"):
      echo x

    let id = dataq_db.tryInsertId(sql"INSERT INTO data_queue (name,i,f) VALUES (?,?,?)",
          "Item#1001", 1001, sqrt(1001.0))
    echo "Inserted item: ", dataq_db.getValue(sql"SELECT name FROM data_queue WHERE id=?", id)

    dataq_db.close()
    
when isMainModule:
    test()