
[app]
name = "log_reversed"
version = "0.1"
# sleep interval in ms
interval = 1000
pattern = "*.nim"
journey = "journey.json"
# ext of the output files
ext = ".data"

[http]
enable= false
bind = "0.0.0.0"
port= 8080

[influxdb]
enable = false
host = "localhost"
port = 8083

[mqtt]
enable= false
host = "localhost"
port = 1883

[redis]
enable= false
host = "localhost"
port = 6379
hbkey = "hb"
db = 1

[logging]
fmt = "($datetime) [$levelname][$pid] $appname: "
log_file = "logs/log_reversed.log"
log_level = "Debug"
max_lines = 1000
backup_count = 5
buffer_size = 0
