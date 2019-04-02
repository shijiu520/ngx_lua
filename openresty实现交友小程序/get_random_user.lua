--local logger = require "resty.logger"
--local log = logger:new('debug', '/opt/log/logfile.log' )
local common = require("common")
local mysql_util = require("mysql_util")

local tool = require("tool")

local redisLib = require("360_redis")
local redisConn = redisLib:new()

--[[

local redisLib = require("redis")
local ok,redisConn = redisLib:get_connect()
if not ok then
    ngx.say("redis server connected failed =================")
    return
end
--]]


redisConn:select(7)

local json = require "cjson.safe"


local redisUsers = redisConn:get("string:system_users")



if redisUsers == ngx.null or redisUsers == nil  then
    local sql = "select nickname,age,gender,beauty,photo from users where user_type=0"
    local users = mysql_util.query(sql)
   

    if tool.table_is_empty(users) then
        tool.toJson(-1,"获取数据为空")
        return
    end

    redisUsers = json.encode(users)
    redisConn:set("string:system_users",redisUsers,"nx","ex",60*60*24)

end

local decode_user = json.decode(redisUsers)


tool.shuffle(decode_user)
tool.shuffle(decode_user)



--redisLib:close()

tool.toJson(0,"获取成功",decode_user)
















