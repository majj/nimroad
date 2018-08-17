




import json
import tables
import typetraits

var data = %* {"a":1, "b":2.1, "c":"test"}


for k,v in pairs(data):
    
    echo k, ":",  v
    
