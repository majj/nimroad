
##
## read_yaml.nim
## 
##  patch for:
##  dom.nim
##  parser.nim
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
import typetraits

import yaml.serialization, yaml.presenter, streams
import yaml

proc test():void = 

    var fs = newFileStream("mts.yaml", fmRead)

    let yaml_str = fs.readAll()
    let parser = newYamlParser()

    var s = parser.parse(yaml_str)
    var yamlResult = constructJson(s)

    let n = yamlResult
    echo n[0]

    #echo n.type.name


    let m = n[0]
    echo m.type.name

    echo m["measurement"]

    if "tags" in m:
        echo m["tags"]

    for k,v in pairs( m["fields"] ):
        echo k, ":", v
        echo v["type"]
        echo "type:", ($v["type"]).type.name


    fs.close()
    
    
if isMainModule:
    test()
    