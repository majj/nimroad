
import json
# import strformat
import strutils
import typetraits

import db_postgres

proc test():void = 
   
    let json_str = %* {"name":"mabo2018"}

    let db = open("localhost:6432", "mabo", "mabo2018", "mabo")


    let c = db.getRow(sql"select max(id) from public.program")
    let id = parseInt(c[0]) + 1

    db.exec(sql("""INSERT INTO public.program(
                id, program_json, createdon, avtive)
        VALUES ($1, '$2', now(), 1)""".format(id, json_str)))

    let x = db.getAllRows(sql"select * from public.program order by id desc limit 5")
    
    for item in x:
        echo item

    db.close()
    
if isMainModule:
    
    test()