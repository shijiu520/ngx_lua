--local logger = require "resty.logger"
--local log = logger:new('debug', '/opt/log/logfile.log' )


local common = require("common")
local mysql_util = require("mysql_util")
local valid = require("valid")
local tool = require("tool")

--[[
local redisLib = require("redis")
local ok,redisConn = redisLib:get_connect()
if not ok then
    ngx.say("redis server connected failed =================")
    return
end
--]]

local redisLib = require("360_redis")
local redisConn = redisLib:new()




redisConn:select(7)

local json = require "cjson.safe"


local args = ngx.req.get_uri_args()
local valid_status = valid.valid_session_key(args)

if not valid_status then
    tool.toJson(-200,"third_session_id 缺失")
    return
end
local third_session_id = args["third_session_id"]


local cache_value = redisConn:hget("hash:session_keys",third_session_id)


if cache_value == ngx.null or cache_value == nil then
    tool.toJson(-100,"登录失效")
    return
end


local cache_value_arr = tool.Split(cache_value,"***")
local openid = cache_value_arr[1]
--local openid = "a595f2bed8dc73240f011c0e9ecd57de"


local user_sql = "select id,openid,nickname,age,gender,beauty,yuan_num,photo from users where openid=" .. ngx.quote_sql_str(openid)


local user = mysql_util.query(user_sql)

if tool.table_is_empty(user) then
    tool.toJson(-1,"请先上传头像")
    return
end


local address_sql = "select username,phone,address,detail from address where user_id="..ngx.quote_sql_str(user[1]["id"])
local addressRow = mysql_util.query(address_sql)


local data = {}

if tool.table_is_empty(addressRow) then
    data.username = ""
    data.phone = ""
    data.address = ""
    data.detail = ""
else
    data.username = addressRow[1]["username"]
    data.phone = addressRow[1]["phone"]
    data.address = addressRow[1]["address"]
    data.detail = addressRow[1]["detail"]
end

tool.toJson(0,"获取成功",data)








