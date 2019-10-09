local core = require "socketcore"
local message = require "message"
local cjson = require "cjson"
local pb = require "pb"


local socket = {}
setmetatable(socket, { __index = core })

local cbs = {
    accept = 1,
    connect = 2,
    read = 3
}

--设置回调函数
function socket.setCallBack(name, cb)
    local n = cbs[name]

    if n then
        core.setCallBack(name, cb)
    else
        error("Do not set call back by name <" .. name .. ">  see 'socket.lua'!")
    end
end

--获取接收到的消息
function socket.getReadmsg(who)
    local msg = core.getReadmsg(who)
    local msgType = core.getMessageType(who)

    if (msgType == message.mt["json"]) then
        return cjson.json2table(msg)
    elseif (msgType == message.mt["proto"]) then
        if (core.getProtoMessageType(who) == message.pmt.SessionMsg) then
            return pb.decode("SessionMsg", msg)
        elseif (core.getProtoMessageType(who) == message.pmt.GameMsg)  then
            return pb.decode("GameMsg", msg)
        elseif (core.getProtoMessageType(who) == message.pmt.RoomMsg)  then
            return pb.decode("RoomMsg", msg)
        end
    elseif (msgType == message.mt["raw"]) then
    else
        error("unknow message type!")
    end

end

return socket