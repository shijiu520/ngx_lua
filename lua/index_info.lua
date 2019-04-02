--local logger = require "resty.logger"
--local log = logger:new('debug', '/opt/log/logfile.log' )


local utils = require("act_set")

local date = os.date


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


local day = utils.getDay()

if day > 4 then 
    tool.toJson(-999,"不在活动期")
    return 
end


local activity_set_sql = "select * from activity_set order by id desc limit 1"
local activity_set = mysql_util.query(activity_set_sql)

if ngx.time() > activity_set[1]["end_timestamp"] then
    tool.toJson(-999,"不在活动期")
    return
end


local rand_words = redisConn:srandmember("set:love_words")


local flop_num = utils.get_num(openid)

local light_num = user[1]["yuan_num"]

local arr = {}

for i=1,7 do
    if i <= light_num then
        table.insert(arr,1) 
    else
        table.insert(arr,0)
    end
end


local data = {}

if rand_words == ngx.null or rand_words == nil  then
    rand_words = "你的脸上有点东西，有什么？有点漂亮"
end


local system_msg_sql = "select * from system_msg where status=1"
local systemMsgIds = mysql_util.query(system_msg_sql)

for k,v in pairs(systemMsgIds) do
    local system_user_message_sql = "select count(*) as num from system_user_message where system_msg_id="..systemMsgIds[k]["id"].. " and user_id="..user[1]["id"]
    local if_count = mysql_util.query(system_user_message_sql)

    if tonumber(if_count[1]["num"]) <=0 then
        local systemTime = systemMsgIds[k]["created_at"]

        if tonumber(systemTime) <= 0 then
            systemTime = ngx.time()
        end

        local insert_sql = "insert into system_user_message (system_msg_id,user_id,msg_type,message,system_time) values ("..systemMsgIds[k]["id"]..","..user[1]["id"]..",2,"..ngx.quote_sql_str(systemMsgIds[k]["message"])..","..systemTime..")"
        mysql_master_util.execute(insert_sql)
        --ngx.say(insert_sql)
    end

end


local ifShare = redisConn:hget("hash:share_"..date("%Y%m%d",ngx.time()),openid)

local today_if_share = 0


if ifShare == ngx.null or ifShare == nil then
    today_if_share = 0
else
    if tonumber(ifShare) > 0 then
        today_if_share = 1
    else
        today_if_share = 0
    end

end


local gender_str = ""
if user[1]["gender"] == 1 then
    gender_str = "男"
else
    gender_str = "女"
end

local user_info = {}
user_info["age"] = user[1]["age"]
user_info["gender_str"] = gender_str
user_info["beauty"] = user[1]["beauty"]


data["light_num"] = arr
data["love_words"] = rand_words
data["photo"] = user[1]["photo"]

data["user_info"] = user_info

data["total_num"] = flop_num
data["ifShare"] = today_if_share
tool.toJson(0,"获取成功",data)






