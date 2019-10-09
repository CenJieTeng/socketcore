local pb = require "pb"
local protoc = require "protoc"


local p = protoc:new()
assert(p:load([[
    message Person{
        optional string name = 1;
        optional int32 age = 2;
    }
]]))

local cjt = {
    name = "CenJieTeng",
    age = 20
}

local bytes = assert(pb.encode("Person", cjt))
print(pb.tohex(bytes))

local data = assert(pb.decode("Person", bytes))
print(require "serpent".block(bytes))