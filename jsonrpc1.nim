import json_rpc/[rpcclient, rpcserver], asyncdispatch2, json

var
  server = newRpcSocketServer("localhost", Port(8545))
  client = newRpcSocketClient()

server.start

server.rpc("hello") do(input: string) -> string:
  result = "Hello " & input

waitFor client.connect("localhost", Port(8545))

let response = waitFor client.call("hello", %[%"Daisy"])

# the call returns a `Response` type which contains the result
echo response.result

runForever()