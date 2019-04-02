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



local user_sql = "select id,openid,nickname,age,gender,beauty,yuan_num,photo from users where openid=" .. ngx.quote_sql_str(openid)


local user = mysql_util.query(user_sql)

if tool.table_is_empty(user) then
    tool.toJson(-1,"请先上传头像")
    return
end


local uid_status = valid.valid_param(args,"uid")

if not uid_status then
    tool.toJson(-2,"缺失参数")
    return
end

local from_user_sql = "select gender,age,photo,beauty from users where id="..ngx.quote_sql_str(args["uid"])

local from_user = mysql_util.query(from_user_sql)

if tool.table_is_empty(from_user) then
    tool.toJson(-3,"用户不存在")
    return
end





local data = {}
data.gender = from_user[1]["gender"]
data["age"] = from_user[1]["age"]
data["photo"] = from_user[1]["photo"]
data["beauty"] = from_user[1]["beauty"]

tool.toJson(0,"获取成功",data)







