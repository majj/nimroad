
# util & helper for client lib of influxdb

import json
import tables
import streams

import yaml

proc yaml2json*(filename: string):seq[JsonNode] = 
    # parse yaml and construct json
    
    var fs = newFileStream(filename, fmRead)
    defer: fs.close()
    
    let parser = newYamlParser()
    let yaml_str = fs.readAll()
    var yaml_p = parser.parse(yaml_str)
    
    return constructJson(yaml_p)
    
proc get_datatype*(data: JsonNode):Table[string, string] = 
    # get field datatype from yaml
    
    var datatype_dict = initTable[string, string]()
    
    for k,v in pairs( data["fields"] ):
        datatype_dict[k] = getStr(v["type"])

    return datatype_dict