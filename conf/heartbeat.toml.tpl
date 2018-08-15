
[app]
name = "heartbeat"
version = "0.1"
# sleep interval in ms
interval = 5000

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
fmt = "($datetime) [$levelname] $appname: "
log_file = "logs/heartbeat.log"
max_lines = 1000
backup_count = 5
buffer_size = 0
