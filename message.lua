local message = {}
local protoc = require "protoc"

--消息类型
message.mt = {
    json = 1,
    proto = 2,
    raw = 3
}

--proto消息类型
message.pmt = {
    SessionMsg = 1,
    GameMsg = 2,
    RoomMsg = 3
}

local p = protoc:new()

--会话消息类型
message.SessionMsgType = {
    close = 1;
    getKey = 2;
    getSeed = 3;
    chat = 4;
    register = 5;
    login = 6;
    logout = 7;
}

--会话控制消息
assert(p:load([[
    message SessionMsg{
        optional int32 MsgType = 1;
        optional bool result = 2;
        optional int32 key = 3;
        optional int32 seed = 4;
        optional string chatMsg = 5;
        optional string name = 6;
        optional string account = 7;
        optional string password = 8;
    }
]]))

--游戏消息类型
message.GameMsgType = {
    create = 1;
    position = 2;
    attack = 3;
    enemyHurt = 4;
    chat = 5;
    getDamage = 6;
}

--游戏消息
assert(p:load([[
    message GameMsg{
        optional int32 MsgType = 1;
        optional float x = 2;
        optional float y = 3;
        optional int32 key = 4;
        optional float angle = 5;
        optional float atk = 6;
        optional int32 enemyTag = 7;
        optional string chatMsg = 8;
        repeated int32 keys = 9;
        repeated float damage = 10;
    }
]]))

--房间消息类型
message.RoomMsgType = {
    create = 1;
    into = 2;
    leave = 3;
    start = 4;
    ready = 5;
    roomlist = 6;
}

--房间消息
assert(p:load([[
    message RoomMsg{
        optional int32 MsgType = 1;
        optional int32 roomId = 2;
        optional bool result = 3;
        repeated int32 roomList = 4;
        repeated bool roomStatuses = 5;
        repeated int32 roomNumOfPeople = 6;
    }
]]))

return message