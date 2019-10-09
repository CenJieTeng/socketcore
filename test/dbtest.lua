local db = require "db"

db.connect("localhost", "root", "5656", "my_test", 3306)

local function fun(v)
    if (v) then
        return v
    else
        return "null"
    end
end

local function showTable()
    print("id   name    gender  age email   score")
    while true do
        local row = db.fetch_row("SELECT * FROM students")
        if (next(row) ~= nil) then
            local str
            str = fun(row["id"]) .. "   " .. fun(row["name"]) .. "   " .. fun(row["gender"]) .. "   " .. fun(row["age"]) .. "   " .. fun(row["email"]) .. "   " .. fun(row["score"])
            print(str)
        else
            break;
        end
    end
end

showTable()

db.insert("students",{"id","name","gender","age","score","email"}, {1005, "cjt", "男", 21, 100, "22@qq.com"})
print("插入数据后---------------")
showTable()

db.updateAll("students", "gender=\"男\"")
print("更改数据后---------------")
showTable()

db.erase("students", "id = 1006")
print("删除数据后---------------")
showTable()

while true do
end