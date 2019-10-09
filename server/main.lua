local socket = require "socket"
local timer = require "timer"
local db = require "db"
local message = require "message"
--local cjson = require "cjson"
local pb = require "pb"
local room = require "room"

local playerKey = 0
local maxPlayerKey = 1024 --最大连接数
local players = {} --客户端表
local hall = {} --在大厅中的客户端表
local playerDamage = {} --各个玩家的伤害
local roomTimerId = {} --房间对应的定时器
--local nameTable = {} --用户名->密码表
local accountTable = {} --账户->密码表
local accountOnlinePlayer = {} --账户->客户端表 保存使用该账户登录的客户端
local playerKeyAccount = {} --客户端key->账户表

--连接到数据库
db.connect("localhost", "root", "5656", "gameserver", 3306)
--从数据库account表加载账户信息
while true do
    local row = db.fetch_row("SELECT * FROM account")
    if (next(row) ~= nil) then
        accountTable[row["account"]] = row["password"]
    else
        break;
    end
end

--分配客户端对应的key
local function newKey()
    local count = 0
    repeat
        playerKey = playerKey % maxPlayerKey + 1

        count = count + 1
        if (count > maxPlayerKey) then return
        end
    until(players[playerKey] == nil)

    return playerKey
end

--序列化proto消息
local function serialize(msg, pmt)
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

    return str
end

--广播消息(players 中的客户端)
--消息
--消息类型
--选择不广播给谁
local function broadcast(msg, pmt, nosend)
    local str = serialize(msg, pmt)

    for _,who in pairs(players) do
        if (who ~= nosend) then
            socket.doWrite(who, str, message.mt.proto, pmt)
        end
    end
end

--广播消息(hall 中的客户端)
--消息
--消息类型
local function hallBroadcast(msg, pmt)
    local str = serialize(msg, pmt)

    for _,who in pairs(hall) do
        socket.doWrite(who, str, message.mt.proto, pmt)
    end
end

--更新客户端的roomlist
local function updateRoomList(sendto)
    local msg = {}
    msg["roomList"] = room.getRoomIds()
    msg["roomStatuses"] = room.getRoomStatuses()
    msg["roomNumOfPeople"] = room.getRoomsPlayerNum()
    msg["MsgType"] = message.RoomMsgType.roomlist

    if (sendto ~= nil) then
        --只发送给某个客户端
        socket.doWrite(sendto, pb.encode("RoomMsg",msg), message.mt.proto, message.pmt.RoomMsg)
    else
        -- --只广播给大厅(roomId == 0) 和 未开始游戏(roomStatus == false)的客户端
        -- for _,who in pairs(players) do
        --     local roomId = socket.getRoomId(who)
        --     if (roomId == 0 or room.getRoomStatus(roomId) == false) then
        --         socket.doWrite(who, pb.encode("RoomMsg",msg), message.mt.proto, message.pmt.RoomMsg)
        --     end
        -- end
        hallBroadcast(msg, message.pmt.RoomMsg)
    end
end

socket.setCallBack("accept", function(who)
    local key = newKey()
    if not key then return
    end

    socket.setKey(who, key) --设置客户端在players表的key
    players[key] = who --添加到表
    playerDamage[key] = 0 --初始化伤害值

    --告诉客户端自己的key
    repeat
        local msg = {}
        msg["key"] = key
        msg["MsgType"] = message.SessionMsgType.getKey
        socket.doWrite(who, pb.encode("SessionMsg", msg), message.mt.proto, message.pmt.SessionMsg)
    until true

    print("accept new client!")
end)

socket.setCallBack("read", function(who)
    --检测key是否合法
    local key = socket.getKey(who)
    if (key <= 0 or key > maxPlayerKey) then
        return
    end

    local msg = socket.getReadmsg(who)--获取消息内容
    local roomId = socket.getRoomId(who)--获取房间id

    if (socket.getProtoMessageType(who) == message.pmt.SessionMsg) then --SessionMsgMsg
        if (msg["MsgType"] == message.SessionMsgType.close) then
            --告诉客户端收到close消息，客户端可以调用iocontext.stop()
            socket.doWrite(who, pb.encode("SessionMsg", msg), message.mt.proto, message.pmt.SessionMsg)
            players[key] = nil --在客户端表中移除
            hall[key] = nil --在大厅表中移除
            --从在线客户端中去除该实例
            for a,p in pairs(accountOnlinePlayer) do
                if (p == who) then
                    accountOnlinePlayer[a] = nil
                end
            end
            msg["key"] = key

            print("client close socket. <key>:" .. key)
        elseif (msg["MsgType"] == message.SessionMsgType.chat) then
            msg["chatMsg"] = tostring(playerKeyAccount[key]) .. ': ' .. msg["chatMsg"]
            hallBroadcast(msg, message.pmt.SessionMsg) --广播给所有人
        elseif (msg["MsgType"] == message.SessionMsgType.register) then
            local account = msg["account"]
            local password = msg["password"]

            --检测 account 是否被注册
            if (account ~= nil and accountTable[account] ~= nil)  then
                msg["result"] = false
            else
                --保存的数据库account表和临时account表中
                db.insert("account",{"account","password"},{account,password})
                accountTable[account] = password
                msg["result"] = true
            end

            --通知客户端register结果
            socket.doWrite(who, pb.encode("SessionMsg", msg), message.mt.proto, message.pmt.SessionMsg)
        elseif (msg["MsgType"] == message.SessionMsgType.login) then
            local account = msg["account"]
            local password = msg["password"]

            --检测 name,account 是存在
            if (account ~= nil and accountTable[account] == password)  then
                msg["result"] = true
                hall[key] = who --添加到大厅

                --检测该账户是否已经被登录
                if (accountOnlinePlayer[account] == nil) then
                    accountOnlinePlayer[account] = who
                    playerKeyAccount[key] = account
                else
                    --把已经登录的踢下线
                    local onlinePlayer = accountOnlinePlayer[account]
                    local msg = {}
                    msg["MsgType"] = message.SessionMsgType.logout
                    socket.doWrite(onlinePlayer, pb.encode("SessionMsg", msg), message.mt.proto, message.pmt.SessionMsg)

                    for k,p in pairs(players) do
                        if (p == onlinePlayer) then
                            --players[k] = who
                            hall[k] = nil
                            playerKeyAccount[k] = nil

                            -- local roomId = socket.getRoomId(onlinePlayer)
                            -- local ret = room.leaveRoom(roomId, onlinePlayer)
                            -- if (ret and roomTimerId[roomId] ~= nil) then
                            --     timer.cancel(roomTimerId[roomId])
                            --     roomTimerId[roomId] = nil
                            -- end
                            -- playerDamage[k] = 0
                        end
                    end

                    playerKeyAccount[key] = account
                    accountOnlinePlayer[account] = who
                end
            else
                msg["result"] = false
            end

            --通知客户端login结果
            socket.doWrite(who, pb.encode("SessionMsg", msg), message.mt.proto, message.pmt.SessionMsg)
            --更新客户端roomlist
            timer.create(100, function()
                updateRoomList(who)
            end, false)
        end
    elseif (socket.getProtoMessageType(who) == message.pmt.GameMsg) then --GameMsg
        if (msg["MsgType"] == message.GameMsgType.create
            or msg["MsgType"] == message.GameMsgType.position
            or msg["MsgType"] == message.GameMsgType.attack
            or msg["MsgType"] == message.GameMsgType.chat) then
                msg["key"] = key
                room.broadcast(roomId, msg, message.pmt.GameMsg)
        elseif(msg["MsgType"] == message.GameMsgType.enemyHurt) then
            if (playerDamage[key] == nil) then
                playerDamage[key] = 0
            end
            playerDamage[key] = playerDamage[key] + msg["atk"]

            msg["key"] = key
            room.broadcast(roomId, msg, message.pmt.GameMsg)
        end
    elseif (socket.getProtoMessageType(who) == message.pmt.RoomMsg) then --RoomMsg
        if (msg["MsgType"] == message.RoomMsgType.create) then
            room.createRoom(who)
            updateRoomList()
        elseif (msg["MsgType"] == message.RoomMsgType.into) then
            room.intoRoom(msg["roomId"], who)
            updateRoomList(); --如果原来所在的房间关闭，更新客户端roomlist
        elseif (msg["MsgType"] == message.RoomMsgType.leave) then
            local ret = room.leaveRoom(roomId, who)
            --如果原来所在的房间关闭，取消定时器
            if (ret and roomTimerId[roomId] ~= nil) then
                timer.cancel(roomTimerId[roomId])
                roomTimerId[roomId] = nil
            end

            hall[key] = who
            playerDamage[key] = 0
            updateRoomList();
        elseif (msg["MsgType"] == message.RoomMsgType.start) then
            room.start(roomId)
            hall[key] = nil --客户端从大厅表中去除
        elseif (msg["MsgType"] == message.RoomMsgType.ready) then
            local ret = room.ready(roomId, who)
            if (ret) then
                --开启定时器，间隔1s统计伤害发送给客户端
                --获取同一房间player的伤害
                roomTimerId[roomId] = timer.create(1000, function()
                    if (room.isExist(roomId)) then
                        local damage = {}
                        for _,k in pairs(room.getPlayerKeys(roomId)) do
                            damage[#damage+1] = playerDamage[k]
                        end

                        msg["MsgType"] = message.GameMsgType.getDamage
                        msg["damage"] = damage
                        msg["keys"] = room.getPlayerKeys(roomId)
                        room.broadcast(roomId, msg, message.pmt.GameMsg)
                    end
                end,true)
                updateRoomList()
            end
        else
            error("Unknow room control type.")
        end
    end
end)

socket.listen("127.0.0.1", 9999)
socket.accept()
socket.run()