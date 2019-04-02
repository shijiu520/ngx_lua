--local logger = require "resty.logger"
--local log = logger:new('debug', '/opt/log/logfile.log' )


local common = require("common")
local mysql_util = require("mysql_util")
local valid = require("valid")
local tool = require("tool")
local redisLib = require("360_redis")
local redisConn = redisLib:new()

--[[
local ok,redisConn = redisLib:get_connect()
if not ok then
    ngx.say("redis server connected failed =================")
    return
end
--]]

redisConn:select(7)

local date = os.date

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

local flop_type = tonumber(args["type"])

if page == nil or page == "undefined" or page == true then
    page = 1
end


if size == nil or size == "undefined" or size == true then
    size = 20
end

if flop_type == nil or flop_type == "undefined" or flop_type == true then
    flop_type = 1
end

if page < 1 then
    page = 1
end

local offset = (page-1) * size


if flop_type == 1 then
    local flop_sql = "select user_id,`type`,flop_user_id,`match`,prize_id,created_at from flop_log where user_id="..ngx.quote_sql_str(user[1]["id"]) .. " order by id desc limit " .. offset .. ","..size
    local log = mysql_util.query(flop_sql)

    local count_sql = "select count(*) as num from flop_log where user_id="..user[1]["id"]

    local totalCount = mysql_util.query(count_sql)

    local totalPage = math.ceil(totalCount[1]["num"]/size)

    local result = {}

    for k,v in pairs(log) do
        local tmp = {}
        tmp["type"] = log[k]["type"]
        tmp["date"] = date("%Y-%m-%d %H:%M",log[k]["created_at"])
        tmp["match_num"] = log[k]["match"]
       
        if log[k]["type"] < 4 then
            local prize_sql = "select id,name,image from prize where id="..log[k]["prize_id"]
            local prizeRow = mysql_util.query(prize_sql)
            tmp["image"] = prizeRow[1]["image"]
            tmp["name"] = prizeRow[1]["name"]
            tmp["from_user_id"] = ""

        elseif log[k]["type"] == 4 then
            local user_sql = "select nickname,photo,nickname_encode from users where id="..log[k]["flop_user_id"]
            local userRow = mysql_util.query(user_sql)
            
            tmp["name"] = ngx.unescape_uri(userRow[1]["nickname_encode"])
            tmp["image"] = userRow[1]["photo"]
            tmp["from_user_id"] = log[k]["flop_user_id"]
        end


        --table.insert(result,tmp)
        result[k] = tmp
    end
    tool.toJson2(0,"获取成功",result,totalPage)
else
    local user_prize_sql = "select prize_name,prize_id,user_id,created_at from user_prize where user_id="..user[1]["id"] .. " order by id desc limit " .. offset .. ","..size
    local log = mysql_util.query(user_prize_sql)

    local count_sql = "select count(*) as num from user_prize where user_id="..user[1]["id"]
    local totalCount = mysql_util.query(count_sql)

    local totalPage = math.ceil(totalCount[1]["num"]/size)

    local result = {}

    for k,v in pairs(log) do
        local tmp = {}
        tmp["type"] = 1
        tmp["date"] = date("%Y-%m-%d %H:%M",log[k]["created_at"])

        tmp["match_num"] = 0

        local prize_sql = "select id,name,image from prize where id="..log[k]["prize_id"]
        local prizeRow = mysql_util.query(prize_sql)
        tmp["image"] = prizeRow[1]["image"]
        tmp["name"] = prizeRow[1]["name"]
        tmp["from_user_id"] = ""
        --table.insert(result,tmp)
        result[k] = tmp
    end

    tool.toJson2(0,"获取成功",result,totalPage)
end
















