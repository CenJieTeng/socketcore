local socket = require("socket")
local message = require("message")

local HOST = "127.0.0.1"
local PORT = 9999

socket.setCallBack("connect", function(who)
    socket.do_write(who, "haha", message.proto)
end)

socket.setCallBack("read", function(who)
    print("recv: " .. socket.get_readmsg(who))
end)

socket.connect(HOST, PORT)
socket.run()

while true do
end