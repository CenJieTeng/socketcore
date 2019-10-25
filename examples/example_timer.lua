local socket = require "socketcore"

local id
local count = 0

id = socket.timer(1000, function()
    print("_" .. count .. "_")
    if (count == 5) then
        socket.timerCancel(id)
    end
    count = count + 1
end, true)

socket.run()

print("done")