
[app]
name = "ak_client"
version = "0.1"

host="127.0.0.1"
port = 9527

# sleep interval in ms
interval = 3000

command = 2
client_id =6

cmd_fmt = "!4b"
data_fmt = "!3b2bff7i2fb"


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
enable= true
host = "localhost"
port = 6379
hbkey = "hb"
db = 1

[logging]
fmt = "($datetime) [$levelname] $appname: "
log_file = "logs/ak_client.log"
max_lines = 1000
backup_count = 5
buffer_size = 0
