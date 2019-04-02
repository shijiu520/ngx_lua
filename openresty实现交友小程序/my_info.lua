--local logger = require "resty.logger"
--local log = logger:new('debug', '/opt/log/logfile.log' )


local common = require("common")
local mysql_util = require("mysql_util")
local valid = require("valid")
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


local data = {}
data.gender = user[1]["gender"]
data["age"] = user[1]["age"]
data["photo"] = user[1]["photo"]
data["beauty"] = user[1]["beauty"]


local if_read_count_sql = "select count(*) as num from system_user_message where user_id="..user[1]["id"].." and if_read=0"
local if_read_count = mysql_util.query(if_read_count_sql)

local if_count_result = if_read_count[1]["num"]
local if_read = 1

if tonumber(if_count_result) > 0 then
    if_read = 0
end


--local user_msg_sql = "select count(*) as num from user_msg where if_read=0"

local user_msg_sql = "select sum(num) as num from(select id,count(distinct(from_user_id)) as num,from_user_id from user_msg where if_read=0 and user_id="..user[1]["id"].." group by from_user_id) a"

local user_msg_count = mysql_util.query(user_msg_sql)


local system_count = 0
if if_read == 0 then
    system_count = 1
end


local msgCount = 0

if not tool.table_is_empty(user_msg_count) then

    if user_msg_count[1]["num"] == ngx.null then
        msgCount = 0
    else
        msgCount = tonumber(user_msg_count[1]["num"])
    end

end


local total_count = system_count + msgCount

data["msg_count"] = total_count

--data["msg_count"] = 3

tool.toJson(0,"获取成功",data)






