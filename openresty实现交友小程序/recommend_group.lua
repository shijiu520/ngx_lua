local common = require("common")
local tool = require("tool")
local redisLib = require("redis")
local model = require("model")
local ok,redisConn = redisLib:get_connect()
if not ok then
    ngx.say("redis server connected failed =================")
    return
end
redisConn:auth('abc$@123')


local json = require "cjson.safe"


local header = ngx.req.get_headers()

local is_header_exists = tool.key_exists("third-session-id",header)

if not is_header_exists then
	tool.toJson(-200,'third-session-id not found OR undefined')
	return
end


local third_session_id = header["third-session-id"]

if not third_session_id or third_session_id == "undefined" or third_session_id=="" or third_session_id==true  then
	tool.toJson(-200,'third-session-id not found OR undefined')
	return
end


local cache_value = redisConn:hget('hash:session_keys',third_session_id)

local now_uri = ngx.var.uri


if cache_value == ngx.null or cache_value == nil then
	if now_uri ~= "/invite_user" then
		tool.toJson(-100,'登录失效')
		return
	end
end

local openid = ""
local sessionKey = ""


if third_session_id then
	local cache_value_arr = tool.Split(cache_value,"***")
	openid = cache_value_arr[1]
	sessionKey = cache_value_arr[2]
end

local user = model.getUserByOpenid(openid)

if tool.table_is_empty(user) then
	if now_uri ~= '/invite_user' then
		tool.toJson(-300,"请先登录授权")
	end
end


local userId = user[1]["id"]

local is_group_owner = 0  --不是xinweishang账号   不可以可以创建圈子

if user[1]["is_business"] == 1 then
	is_group_owner = 1
end

local groupCount = model.getRecommendGroupCount()

local res = {}
local rid = {}

for i=1,20 do
	if #res >= 8 then
		break
	end

	math.randomseed (ngx.now())

	local offset = math.random(1, groupCount)

	local r = model.getOneByOffset(offset)
	if not tool.table_is_empty(r) then

		while true do --实现continue 效果
			if tool.in_array(r[1]["id"],rid) then
				break
			end

			if r[1]["opened"] == 3 then
				break
			end

			local groupUserTmp = model.getGroupUserByUidGid(user[1]["id"],r[1]["id"])
			if not tool.table_is_empty(groupUserTmp) then
				break
			end

			local black = model.getGroupBlackByUidGid(user[1]["id"],r[1]["id"])
			if not tool.table_is_empty(black) then
				break
			end


			table.insert(res,r)
			table.insert(rid,r[1]["id"])

			break

		end
	end

end


local result = {}

for k,v in pairs(res) do
	local tmpUser = model.getUserByUid(res[k]["group_owner_id"])

	if tool.table_is_empty(tmpUser) then
		tmpUser = nil
	end

	local tmp = {}
	tmp["name"] = res[k]["name"]
	tmp["image"] = res[k]["image"] or 'https://imgs.meibugou.cn/day_sign/default.png'
	tmp['nickName'] = (tmpUser and (tmpUser[1]["my_nickname"] or ngx.unescape_uri(tmpUser[1]["nickname_encode"]))) or ''
	tmp["intro"] = res[k]["intro"],
	tmp["is_group_owner"] = res[k]["is_group_owner"],
	tmp["opened"] = res[k]["opened"]
	tmp["group_id"] = res[k]["id"]
	tmp["additional"] = res[k]["additional"]
	table.insert(result,tmp)
end


tool.toJson(0,"ok",result)






