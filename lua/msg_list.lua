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


local page = tonumber(args["page"])

local size = tonumber(args["size"])

--local flop_type = tonumber(args["type"])

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

local result = {}

if offset == 0 then
    local userSystemMessageSql = "select id,system_msg_id,user_id,system_time,msg_type,message,if_read from system_user_message where user_id="..user[1]["id"] .. " order by system_time desc limit 1"
    local userSystemMessage  = mysql_util.query(userSystemMessageSql)




    if not tool.table_is_empty(userSystemMessage) then

        local if_read_count_sql = "select count(*) as num from system_user_message where user_id="..user[1]["id"].." and if_read=0"
        local if_read_count = mysql_util.query(if_read_count_sql)

        local if_count_result = if_read_count[1]["num"]

        local if_read = 1

        if tonumber(if_count_result) > 0 then
            if_read = 0
        end


        local u = {}
        u["match_num"] = 0
        u["message"] = userSystemMessage[1]["message"]
        u["from_user_id"] = -1
        u["photo"] = ""
        u["nickname"] = "系统消息"
        u["msg_type"] = 2
        u["if_read"] = if_read

        table.insert(result,u)
    end
    
    size = size - 1
else
    offset = offset - 1

end

local sql = "SELECT * from (SELECT id,uid,message,created_at,message_encode FROM ((SELECT id,user_id as uid,message,created_at,message_encode FROM user_msg WHERE from_user_id = " ..user[1]["id"].. ")UNION (SELECT id,from_user_id as uid,message,created_at,message_encode FROM user_msg WHERE user_id = " ..user[1]["id"].. ") ORDER BY id DESC) as tmp GROUP BY tmp.uid ORDER BY tmp.id DESC limit " ..offset .. ",".. size .. ") as t"

local msgs = mysql_util.query(sql)




local countSql = "SELECT count(*) as num from (SELECT id,uid,message,created_at,message_encode  FROM ((SELECT id,user_id as uid,message,created_at,message_encode FROM user_msg WHERE from_user_id = " ..user[1]["id"].. ")UNION  (SELECT id,from_user_id as uid,message,created_at,message_encode FROM user_msg WHERE user_id = " ..user[1]["id"].. ") ORDER BY id DESC) as tmp GROUP BY tmp.uid ) as t"



local msg_count = mysql_util.query(countSql)


local totalPage = math.ceil(msg_count[1]["num"]/size)

local table_insert = table.insert

for k,v in pairs(msgs) do

    local tmp = {}
    local flop_log_sql = "select `match` from flop_log where type=4 and flop_user_id="..msgs[k]["uid"] .. " and user_id="..user[1]["id"]
    local flopLog = mysql_util.query(flop_log_sql)

    local flop_log_sql2 = "select `match` from flop_log where type=4 and flop_user_id="..user[1]["id"] .. " and user_id="..msgs[k]["uid"]
    local flopLog2 = mysql_util.query(flop_log_sql2)


    local matchs = 0
    if not tool.table_is_empty(flopLog) then
        matchs = flopLog[1]["match"]  
    elseif not tool.table_is_empty(flopLog2) then
        matchs = flopLog2[1]["match"]
        
    end
    tmp["match_num"] = matchs
    --tmp["message"] = msgs[k]["message"]
    tmp["message"] = ngx.unescape_uri(msgs[k]["message_encode"])
    tmp["from_user_id"] = msgs[k]["uid"]

    local tmp_user_sql = "select photo,nickname,id,nickname_encode from users where id="..msgs[k]["uid"]
    local tmpUser = mysql_util.query(tmp_user_sql)
    tmp["photo"] = tmpUser[1]["photo"]
    tmp["nickname"] = ngx.unescape_uri(tmpUser[1]["nickname_encode"])
    tmp["msg_type"] = 1

    local if_count_sql = "select count(*) as num from user_msg where user_id="..user[1]["id"] .. " and from_user_id=" .. msgs[k]["uid"] .. " and if_read=0"
    local if_count = mysql_util.query(if_count_sql)

    if tonumber(if_count[1]["num"]) > 0 then
        tmp["if_read"] = 0
    else
        tmp["if_read"] = 1
    end

    table_insert(result,tmp)
    --result[k] = tmp
end

tool.toJson2(0,"获取成功",result,totalPage)












