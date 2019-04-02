--local logger = require "resty.logger"
--local log = logger:new('debug', '/opt/log/logfile.log' )

local date = os.date
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
local valid_status = valid.valid_session_key(args)

if not valid_status then
    tool.toJson(-200,"third_session_id 缺失")
    return
end
local third_session_id = args["third_session_id"]


local cache_value = redisConn:hget("hash:session_keys",third_session_id)


if cache_value == ngx.null or cache_value == nil  then
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


local page = tonumber(args["page"])

local size = tonumber(args["size"])


if page == nil or page == "undefined" or page == true then
    page = 1
end


if size == nil or size == "undefined" or size == true then
    size = 20
end


if page < 1 then
    page = 1
end

local offset = (page-1) * size


local valid_status_msg_type = valid.valid_param(args,"msg_type")

if not valid_status_msg_type then
    tool.toJson(-2,"缺失参数msg_type")
    return
end


local valid_status_fromUserId = valid.valid_param(args,"from_user_id")

if not valid_status_fromUserId then
    tool.toJson(-2,"缺失参数from_user_id")
    return
end

local msg_type = tonumber(args.msg_type)
local from_user_id = tonumber(args.from_user_id)

if msg_type == 1 then
    local sql = "(select user_id,message,id,from_user_id,created_at,message_encode from user_msg where user_id="..user[1]["id"].." and from_user_id="..from_user_id..") UNION (select user_id,message,id,from_user_id,created_at,message_encode from user_msg where user_id="..from_user_id.." and from_user_id="..user[1]["id"]..") order by id asc limit "..offset..","..size..""



    local msgList = mysql_util.query(sql)

    local countSql = "select sum(num) as num from ((select count(*) as num from user_msg where user_id="..user[1]["id"].." and from_user_id="..from_user_id..") UNION ALL  (select count(*) as num from user_msg where user_id="..from_user_id.." and from_user_id="..user[1]["id"]..")) a"
    local msgCount = mysql_util.query(countSql)
    local msg_count = tonumber(msgCount[1]["num"])
    local totalPage = math.ceil(msg_count/size)


    local result = {}

    for k,v in pairs(msgList) do
        local tmp = {}
        tmp["msg_type"] = 1
        tmp["time"] = date("%Y-%m-%d %H:%M",msgList[k]["created_at"])
        --tmp["message"] = msgList[k]["message"]
        tmp["message"] = ngx.unescape_uri(msgList[k]["message_encode"])
        if msgList[k]["from_user_id"] == user[1]["id"] then
            local tmpUserSql = "select photo from users where id="..user[1]["id"]
            local tmpUser = mysql_util.query(tmpUserSql)
            tmp["photo"] = tmpUser[1]["photo"]
            tmp["uid"] = user[1]["id"]
            tmp["type"] = 1
        elseif msgList[k]["from_user_id"] == from_user_id then
            tmp["type"] = 2
            local tmpUserSql = "select photo from users where id="..from_user_id
            local tmpUser = mysql_util.query(tmpUserSql)
            tmp["photo"] = tmpUser[1]["photo"]
            tmp["uid"] = from_user_id
        end

        table.insert(result,tmp)

    end

    --全部更新为已读
    
    local updateSql = "update user_msg set if_read=1 where user_id="..user[1]["id"].." and from_user_id="..from_user_id
    mysql_master_util.execute(updateSql)

    tool.toJson2(0,"获取成功",result,totalPage)
    return
else
    --"id",'system_msg_id','user_id','system_time','msg_type','message','if_read'
    local sql = "select id,system_msg_id,message,user_id,system_time,if_read,msg_type from system_user_message where user_id="..user[1]["id"] .." order by system_time asc limit ".. offset .. ","..size
    local msgList = mysql_util.query(sql)

    local countSql = "select count(*) as num from system_user_message where user_id="..user[1]["id"]
    local msgCounts = mysql_util.query(countSql)
    local msgCount = msgCounts[1]["num"]

    local totalPage = math.ceil(msgCount/size)

    local result = {}

    for k,v in pairs(msgList) do
        local tmp = {}
        tmp["photo"] = ""
        tmp["message"] = msgList[k]["message"]
        tmp["uid"] = 1
        tmp["time"] = date("%Y-%m-%d %H:%M",msgList[k]["system_time"])
        tmp["type"] = 1
        tmp["msg_type"] = 2
        table.insert(result,tmp)

    end

    local updateSql = "update system_user_message set if_read=1 where user_id="..user[1]["id"]
    mysql_master_util.execute(updateSql)


    tool.toJson2(0,"获取成功",result,totalPage)

end



