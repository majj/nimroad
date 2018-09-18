
# watchdog.nim

##  watchdog for chitu, gateway, etc.

##  ping redis
##  ping ziyan
##  ping chitu
##  check os

import os

import redisparser 
import redisclient

proc restart():int = 
    echo "restart"    
    return 0
    
proc ping_redis():int = 
    echo "PING redis"    
    return 0
    
proc ping_ziyan():int = 
    echo "ping ziyan"
    return 0

proc ping_chitu():int = 
    echo "ping chitu"
    return 0

proc check_os():int = 
    echo "os"
    return 0

proc check_all():void = 
    discard ping_redis()
    discard ping_ziyan()
    discard ping_chitu()
    discard check_os()
    echo "checked"
    
proc redis_dump():void = 
    echo "dump"
    
proc redis_load():void =
    echo "load"
    
proc report():void = 
    # log, mail, etcd, influxdb...
    echo "report"
    
proc main():void = 

    while true:
        try:
            check_all()        
        except:
            echo("error")            
        finally:    
            sleep(1000)
        
        
when isMainModule:
    main()
        





