--local logger = require "resty.logger"
--local log = logger:new('debug', '/opt/log/logfile.log' )


local common = require("common")
local mysql_util = require("mysql_util")
local mysql_master_util = require("mysql_master_util")
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
    
--ngx.req.read_body()
--local args, err = ngx.req.get_post_args()


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


local valid_status_formId = valid.valid_param(args,"formId")

if not valid_status_formId then
    tool.toJson(-2,"缺失参数")
    return
end

local formId = args.formId



if formId == "the formId is a mock one" then
    tool.toJson(-4,"模拟器不记录")
    return
end

redisConn:select(11)

local first_push_key = "first_push_key"
local second_push_key = "second_push_key"
local third_push_key = "third_push_key"

local formIdNums = redisConn:hget("formIdNums",openid)

if formIdNums == ngx.null or formIdNums == nil then
    formIdNums = 0
end

if tonumber(formIdNums) >= 5 then
    tool.toJson(-3,"够了")
    return
end


redisConn:hincrby("formIdNums",openid,1)


if redisConn:hget(first_push_key,openid) == ngx.null or redisConn:hget(first_push_key,openid) == nil then
    redisConn:hset(first_push_key,openid,formId)

elseif redisConn:hget(second_push_key,openid) == ngx.null or redisConn:hget(second_push_key,openid) ==nil then
    redisConn:hset(second_push_key,openid,formId)

elseif redisConn:hget(third_push_key,openid) == ngx.null or redisConn:hget(third_push_key,openid) == nil then
    redisConn:hset(third_push_key,openid,formId)
elseif redisConn:hget("four_push_key",openid) == ngx.null or redisConn:hget("four_push_key",openid) == nil  then
    redisConn:hset("four_push_key",openid,formId)

else
    redisConn:hset("five_push_key",openid,formId)
end

tool.toJson(0,"ok")




