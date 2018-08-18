
import strutils
import os
import times
import threadpool

const str = ["Enjoy", "Rosetta", "Code"]
 
proc f(i:int) =  #{.thread.} 
    let tid = getThreadId()
    #echo tid, now(),'\n'
    echo("""$1, $2£¬$3;""".format(now(),  tid, str[i]))
    sleep(1000)
    echo("""$1, $2;""".format( now(), tid,))
 
for i in 0..str.high:
  spawn f(i)
  
sync()