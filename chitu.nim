
##
##  
##  get data from redis (msgpack, json)
##  
##  send data to influxdb(cluster)
##  
##  if sink failed then retry n times.
##  all failed then save data to redis (retry queue)
##  when send failed,send alert(smtp)
##  ping influxdb when there is communication issue.
##

import parsetoml

import lib.logging
import lib.utils

# main
proc main():void = 

    let config = get_config("conf/watchman.toml")

    echo toTomlString(config["app"])

    let log_conf = config["logging"]

    let rLogger = get_logger(log_conf)

    logging.addHandler(rLogger)

    info("start...")
    
    

# main
if isMainModule:
    main()
