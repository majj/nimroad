
##
## read_yaml.nim
## 
##  patch for:
##  dom.nim
##  stream.nim
##
##  add:
##
##  when defined(nimNoNil):
##      {.experimental: "notnil".}
##
## yaml checker in python: check_conf.py
##

import json
import tables
import typetraits

#import yaml.serialization, yaml.presenter
#import yaml
#import streams

import lib.influx_schema
    
proc test(fn: string):Table[string, string] = 

    let n =yaml2json(fn)
    echo n[0]

    #echo n.type.name

    let m = n[0]
    echo m.type.name

    echo m["measurement"]

    if "tags" in m:
        echo m["tags"]
    
    var tab = initTable[string, string]()
    #tab = {}.toTable
    for k,v in pairs( m["fields"] ):
        echo k, ":", v
        echo v["type"]
        tab[k] = getStr(v["type"])
        echo "type:", ($v["type"]).type.name

    return tab
   
if isMainModule:
    
    var fn: string = "nt3.yaml"
    
    let data = yaml2json(fn)
    
    let t = get_datatype(data[0])
    
    echo t    
    
    discard test(fn)
    