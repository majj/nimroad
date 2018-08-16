

##  msgpack to json
##  nimble install msgpack4nim


import json
import tables
import typetraits
#import typeinfo

import msgpack4nim, msgpack2any, msgpack2json


proc test():void = 
    let  data =  "\x84\xa4time\xcf\x15E\xc6\xa1\xf7\xc1j\x00\xabmeasurement\xa7station\xa4tags\x81\xa6eqptNo\xa5mts01\xa6fields\x83\xa4temp\xcb?\xb9\x99\x99\x99\x99\x99\x9a\xa3log\xa4info\xa2ct\x15"

    var s = MsgStream.init(data, encodingMode = MSGPACK_OBJ_TO_MAP)

    echo "data:", data.toAny()
    echo "data:", data.toAny().type.name
    echo "s.data", s.data.toAny().type.name

    let v2 = s.data.toAny()

    echo v2["time"]

    let v3 = s.data.toJsonNode()
    echo "--data--"
    echo v2
    echo v3
    
    var v4 = fromJsonNode(v3)
    echo "---> v4:",v4.repr
    #echo v3

    echo(s.repr)
    let data_str = s.data.stringify()

    ##  let d = parseJson(data_str)

    echo (v3["time"])
    echo (v3["measurement"])

    let v5 = %*{"v":"vv","yy":112}
    #echo v5.type.name, v5.kind
    #v3["tags"].add(v5)
    echo "-------tags kind---------"

    #v3["fields"]["xx"] = %("yy")
    echo (v3["tags"])

    
    #fields.add(v5)

    

    #v3["xx"]= v5

    #v3.delete("xx")

    #v3["fields"].add(v5)
    echo "-------fields kind---------"
    let fields = copy(v3["fields"])
    echo fields
    #echo v3

    for k,v in json.pairs(fields):
        echo(k,":",v)


when isMainModule:
    test()