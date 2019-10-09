local core = require "socketcore"

local timer = {}

--创建定时器
--msTime 时间（毫秒）
--callBack 回调函数
--loop 是否循环
function timer.create(msTime, callBack, loop)
    return core.timer(msTime, callBack, loop)
end

--取消定时器
function timer.cancel(id)
    core.timerCancel(id)
end

return timer