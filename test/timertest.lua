local socket = require "socket"

local count = 0
local id
id = socket.timer(1000, function()
    count = count + 1
    print(count)

    if (count == 3) then
        socket.timerCancel(id)

        socket.timer(500, function()
            print('w')
        end, true)
    end
end, true)

socket.run()

print("done")

while (true) do
end