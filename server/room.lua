local socket = require "socket"
local message = require "message"
local pb = require "pb"

local room = {}

local maxRoomId = 100 --最大房间数
local maxPlayerNum = 2 --房间最多人数
local rooms = {} --房间列表
local roomStatuses = {} --房间状态
local playerReady = {} --玩家准备状态

math.randomseed(tostring(os.time()))--设置随机数种子
local seed = math.random(1, 100) --获得同步客户端随机数的种子

--单位 s
local function sleep(n)
    if n > 0 then
        os.execute("ping -n " .. tonumber(n + 1) .. " localhost > NUL")
    end
end

--同一房间所以玩家准备就绪
local function allReady(roomId)
    local ready = true

    --同一房间的所有玩家
    for _,p in pairs(rooms[roomId]) do
        local key = socket.getKey(p)
        if (playerReady[key] == nil or playerReady[key] == false) then
            return false
        end
    end

    return ready
end

--判断房间是否存在
function room.isExist(roomId)
    if (roomId == nil) then
        print("RoomId is nil")
    end

    if (rooms[roomId] == nil) then
        return false
    else
        return true
    end
end

--获取房间id集合
function room.getRoomIds()
    local roomIds = {}
    for id,_ in pairs(rooms) do
        roomIds[#roomIds+1] = id
    end

    return roomIds
end

--获取房间status集合
function room.getRoomStatuses()
    local statuses = {}
    for _,s in pairs(roomStatuses) do
        statuses[#statuses+1] = s
    end
    return statuses
end

--获取房间状态
function room.getRoomStatus(RoomId)
    return roomStatuses[RoomId]
end


--获取(各个)房间人数集合
function room.getRoomsPlayerNum()
    local roomNumofPeople = {}
    for _,r in pairs(rooms) do
        roomNumofPeople[#roomNumofPeople+1] = #r
    end
    return roomNumofPeople
end

--获取房间人数
function room.getPlayerNum(roomId)
    if (room.isExist(roomId) == false) then
        error("GetPlayerNum fail. check roomId or room exist")
    end
    return #(rooms(roomId))
end

--获取同一房间的player集合
function room.getPlayers(roomId)
    if (room.isExist(roomId) == false) then
        error("GetPlayerNum fail. check roomId or room exist")
    end

    local players = {}
    for _,p in pairs(rooms[roomId]) do
        players[#players+1] = p
    end

    return players
end

--获取同一房间的keys
function room.getPlayerKeys(roomId)
    if (room.isExist(roomId) == false) then
        error("GetPlayerNum fail. check roomId or room exist")
    end

    local keys = {}
    for _,p in pairs(rooms[roomId]) do
        keys[#keys+1] = socket.getKey(p)
    end

    return keys
end

--在房间广播
function room.broadcast(roomId, msg, pmt)
    if (room.isExist(roomId) == false) then
        error("Room broadcast fail. check roomId or room exist")
    end

    local str
    if (pmt == message.pmt.SessionMsg) then
        str = pb.encode("SessionMsg", msg)
    elseif (pmt == message.pmt.GameMsg) then
        str = pb.encode("GameMsg", msg)
    elseif (pmt == message.pmt.RoomMsg) then
        str = pb.encode("RoomMsg", msg)
    else
        error("unknow proto message type!")
    end

    for _,v in pairs(rooms[roomId]) do
        socket.doWrite(v, str, message.mt.proto, pmt)
    end
end

--创建房间
function room.createRoom(player)
    local count = 0
    local roomId = 0
    repeat
        roomId = roomId % maxRoomId + 1

        count = count + 1
        if (count > maxRoomId) then return
        end
    until(rooms[roomId] == nil)

    socket.setRoomId(player, roomId)
    rooms[roomId] = {} --新建房间
    rooms[roomId][1] = player --加入房间
    roomStatuses[roomId] = false

    --返回房间id给客户端
    local msg = {}
    msg["roomId"] = roomId
    msg["MsgType"] = message.RoomMsgType.create
    socket.doWrite(player, pb.encode("RoomMsg", msg), message.mt.proto, message.pmt.RoomMsg)
end

--获取房间
function room.getRoom(roomId)
    if (room.isExist(roomId) == false) then
        error("Get room fail. check roomId or room exist")
    end

    return rooms[roomId]
end

--进入房间
function room.intoRoom(roomId, player)
    local msg = {}
    msg["MsgType"] = message.RoomMsgType.into
    if roomId == nil
        or rooms[roomId] == nil
        or roomStatuses[roomId] == true 
        or #(rooms[roomId]) >= maxPlayerNum then
        --error("Into room fail. check roomId or room exist")
        --通知客户端房间不存在 or 已经开始游戏 or 满人
        socket.doWrite(player, pb.encode("RoomMsg",msg), message.mt.proto, message.pmt.RoomMsg)
        return true
    else
        --如果已经在某个房间中，先离开原来的房间
        local close = false
        local oldRoomId = socket.getRoomId(player)
        if (oldRoomId ~= 0) then
            close = room.leaveRoom(oldRoomId, player)
        end

        socket.setRoomId(player, roomId)

        msg["result"] = true
        msg["roomId"] = roomId
        socket.doWrite(player, pb.encode("RoomMsg",msg), message.mt.proto, message.pmt.RoomMsg)
        rooms[roomId][#rooms[roomId]+1] = player

        return close
    end
end

--离开房间
function room.leaveRoom(roomId, player)
    if (room.isExist(roomId) == false) then
        error("Leave room fail. check roomId or room exist")
    end

    --从房间中移除该用户
    for k,v in pairs(rooms[roomId]) do
        if (v == player) then
            rooms[roomId][k] = nil
        end
    end
    socket.setRoomId(player, 0)

    playerReady[socket.getKey(player)] = false --unready

    local close = false --是否关闭房间
    --如果房间人数为0，关闭该房间
    if (#rooms[roomId] == 0) then
        rooms[roomId] = nil
        close = true
    end

    --通知房间同一房间的其它客户端删除用户实例
    if (room.isExist(roomId)) then
        local msg = {}
        msg["key"] = socket.getKey(player)
        msg["MsgType"] = message.SessionMsgType.close
        room.broadcast(roomId, msg, message.pmt.SessionMsg)
    end

    return close
end

--开始游戏(进入准备开始的状态，还没真正开始游戏，等待客户端ready后开始)
function room.start(roomId)
    if (room.isExist(roomId) == false) then
        error("Start game fail. check roomId or room exist")
    end

    --通知客户端进入准备状态，并发送ready给服务器
    local msg = {}
    msg["MsgType"] = message.RoomMsgType.start
    room.broadcast(roomId, msg, message.pmt.RoomMsg)

    roomStatuses[roomId] = true --更改房间状态
end

--房间内所有玩家准备完毕开始游戏
function room.ready(roomId, player)
    playerReady[socket.getKey(player)] = true --ready

    if (allReady(roomId)) then
        --同步随机数种子
        repeat
            local msg = {}
            msg["seed"] = seed
            msg["MsgType"] = message.SessionMsgType.getSeed
            room.broadcast(roomId, msg, message.pmt.SessionMsg)
        until true

        --通知客户端创建玩家实例
        for _,v in pairs(rooms[roomId]) do
            local msg = {}
            msg["key"] = socket.getKey(v)
            msg["MsgType"] = message.RoomMsgType.create
            room.broadcast(roomId, msg, message.pmt.GameMsg)
        end

        return true
    end

    return false
end

return room