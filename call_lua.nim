
##

import 
    os,
    strutils

import 
    lib/nimLua
    
## run lua script
proc run(L: PState, fileName: string) =

    if L.doFile(fileName) != 0.cint:
        echo L.toString(-1)
        L.pop(1)
        quit()
    else:
        discard

## main 
proc main() =
    
    # new PState
    var L = newNimLua()
    
    ## test
    for i in 0..10:
      
        var test:seq[string] = @["this", "is","a" ,"sample"]
        
        proc geti():seq[string] =
            return test

        proc getj():int =
            return i
        
        var jstr = """{"b3":"a2","ts":$1}""".format((i+1)*(i+1))
        
        proc get_args():string =
            return jstr

        L.bindFunction:
            [geti] -> "geti"
            [getj] -> "getj"
            [get_args] -> "ARGS"
            
        L.run("conf/nim_lua_test.lua")
        echo (L.toString(-1))        
        #echo @[getTotalMem(),getOccupiedMem(), getFreeMem()]
        echo "------------------>",i
        
        sleep(3000)
        
    L.close()


when isMainModule:
    
    main()