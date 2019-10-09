local core = require "socketcore"

local db = {}

--连接数据库
--host 主机地址(string)
--user 用户名(string)
--password 密码(string)
--database 要打开的数据库(string)
--port 端口(number) 默认3306
function db.connect(host, user, password, database, port)
    core.db_connect(host, user, password, database, port)
end

--一般查询
--sql sql语句(string)
function db.query(sql)
    core.db_query(sql)
end

--student表，段数据类型
local students = {}
students.type = {
    id = "number",
    name = "string",
    gender = "string",
    age = "number",
    email = "string",
    score = "number"
}

--account表，段数据类型
local account = {}
account.type = {
    account = "string",
    password = "string"
}

--插入数据
--tb_name 表名(string)
--fields 段名(table)
--values 段对应的数据(table)
function db.insert(tb_name, fields, values)
    local table
    if (tb_name == "students") then
        table = students
    elseif (tb_name == "account") then
        table = account
    else
        error("Not exist table fields information by " .. tb_name)
    end

    assert(#fields == #values, "Fields and values amount not correspond!")
    local sql = "INSERT INTO " .. tb_name .. "("
    for i=1,#fields do
        if (i == 1)then
            sql = sql .. fields[i]
        else
            sql = sql .. "," .. fields[i]
        end
    end
    sql = sql .. ") VALUES("

    for i=1,#fields do
        if (i == 1) then
            if (table.type[fields[i]] == "string") then
                sql = sql .. "\"" .. tostring(values[i]) .. "\""
            else
                sql = sql .. tostring(values[i])
            end
        else
            if (table.type[fields[i]] == "string") then
                sql = sql .. "," .. "\"" .. tostring(values[i]) .. "\""
            else
                sql = sql .. "," .. tostring(values[i])
            end
        end
    end
    sql = sql .. ")"

    db.query(sql)
end

--删除数据
--tb_name 表名(string)
--condition 条件(string)
function db.erase(tb_name, condition)
    assert(condition ~= nil and type(condition) == "string", "condition must not nil and type is string")
    local sql = "DELETE FROM " .. tb_name .. " WHERE " .. condition
    db.query(sql)
end

--更新数据
--tb_name 表名(string)
--change 更新的段(string) 格式："field1=value,field2=value"
--condition 条件(string)
function db.update(tb_name, change, condition)
    assert(change ~= nil and type(change) == "string" and condition ~= nil and type(condition) == "string", "change and condition must not nil and type is string")
    local sql = "UPDATE " .. tb_name .. " SET " .. change .. " WHERE " .. condition
    db.query(sql)
end

--更新数据(ALL)
function db.updateAll(tb_name, change)
    local sql = "UPDATE " .. tb_name .. " SET " .. change
    db.query(sql)
end

--获取一行结果
--sql sql语句，限制只能是查询语句
function db.fetch_row(sql)
    return core.db_fetch_row(sql)
end

return db