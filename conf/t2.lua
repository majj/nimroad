
-- http://www.inf.puc-rio.br/~roberto/struct/

local struct = require "struct"

--~ local socket = require "socket"

local packed = struct.pack('<LIhBsbfd', 1234, 123456789, -3200, 255, 'Test message', -1, 1.56789, 1.56789)
local L, I, h, B, s, b, f, d = struct.unpack('<LIhBsbfd', packed)
print(L, I, h, B, s, b, f, d)


--~ print(socket._VERSION)

--~ local address = "192.168.1.1"
--~ local port = 80
--~ local client = assert (socket.connect(address, port))

--~ client:close()


local h = require "socket.http"
local res, code, headers, status = 
  h.request([[https://news.sina.com.cn/]])
-- print(res)
print(status)