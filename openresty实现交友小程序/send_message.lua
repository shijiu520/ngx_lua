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


local h_method = ngx.req.get_method()

local args = {}
local err = ""
    
if h_method == "GET" then

     args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args, err = ngx.req.get_post_args()
end



if not args then
    tool.toJson(-1,"缺失参数")
    return
end

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




local valid_status_toUserId = valid.valid_param(args,"to_user_id")

if not valid_status_toUserId then
    tool.toJson(-2,"缺失参数")
    return
end

local to_user_id = tonumber(args.to_user_id)


local words = args.words



local valid_status_words = valid.valid_param(args,"words")

if not valid_status_words then
    words = redisConn:srandmember("set:love_words")
    if words ~= ngx.null or words ~= nil then
        words = ngx.quote_sql_str(words)
    end
end





if words ~= nil then
    words = ngx.quote_sql_str(words)
end

local sql_insert = "insert into user_msg (user_id,from_user_id,message,created_at,message_encode) values ("..to_user_id..","..user[1]["id"]..","..words..","..ngx.time()..","..ngx.escape_uri(words)..")"
local affectRows = mysql_master_util.execute(sql_insert)
if tonumber(affectRows) > 0 then
    tool.toJson(0,"发送成功")
    return
else
    tool.toJson(1,"发送失败，请重试")
end

