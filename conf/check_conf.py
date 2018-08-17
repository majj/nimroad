
### Configuration files(YAML, toml, json) format checker

### pip install ruamel.yaml

import sys
import json

import toml

from ruamel.yaml import YAML

import yaml

def main(conf):
    
    yaml2 = YAML()
    
    fmt = conf.split(".")[-1]
    
    f = open(conf)
    
    if fmt == "yaml":
        y = yaml2.load(f)
        f1 = open(conf)
        z = yaml.load(f1)
    elif fmt == "toml":
        y = toml.load(f)
    else:
        raise(fmt)
        
    ### print (y)
    print(json.dumps(y, indent=4, sort_keys=True))
    print(yaml.dump(y, indent=4, default_flow_style=False))
    
    ### yaml2.explicit_start = True
    ### #yaml.dump(y, sys.stdout)
    ### yaml2.indent(sequence=4, offset=2)
    ### yaml2.dump(y, sys.stdout)
    
    
    ### print(type(z))
    ### #new_toml_string = dict(toml.dumps(z))
    ### #print(new_toml_string)
    ### print(toml.dumps(z))

def main2(conf):
    
    yaml2 = YAML()
    f = open(conf)
    y = yaml2.load(f)
    yaml2.explicit_start = True
    #yaml.dump(y, sys.stdout)
    yaml2.indent(sequence=2, offset=2)
    yaml2.dump(y, sys.stdout)
    
if __name__ == "__main__":
    
    conf = r'mts2.yaml'
    conf = r'watchman1.toml'
    
    conf = r'mts3.yaml'
    
    main2(conf)