local common = require("common")
local mysql_util = require("mysql_util")


local _M = {}

--根据openid 获取用户信息
function _M.getUserByOpenid(openid)

	if not openid or openid==nil or openid=="" then
		return nil
	end

	local sql = "select id,nickname,nickname_encode,headimgurl,status,create_time,if_notice,notice_time1,"..
	"notice_time2,money,openid,phone,is_business,my_nickname,my_avatar,sign,share_head from user where openid="..ngx.quote_sql_str(openid).." and status=1"
	local user = mysql_util.query(sql)
	return user
end


--根据user_id 获取用户信息
function _M.getUserByUid(uid)

	if not uid or uid==nil or uid=="" then
		return nil
	end

	local sql = "select id,nickname,nickname_encode,headimgurl,status,create_time,if_notice,notice_time1,"..
	"notice_time2,money,openid,phone,is_business,my_nickname,my_avatar,sign,share_head from user where id="..uid.." and status=1"
	local user = mysql_util.query(sql)
	return user
end




--获取推荐圈子数量(显示在首页随机推荐的)
function _M.getRecommendGroupCount()
	local sql = "select count(*) as countNum from group where status=1 and opened < 3"
	return mysql_util.query(sql)
end

--根据偏移量从group 表查询一条记录
function _M.getOneByOffset(offset)
	local sql = "select id,name,intro,group_owner_id,opened,announcement,additional,supplement,"..
	"sup_type,sup_num,punching_activity,status,create_time,is_recommend,image"..
	" from group where status=1 limit %d,1"
	sql = string.format(sql,offset)

	return mysql_util.query(sql)
end

-- 根据user_id,group_id 从group_user 表查询一条记录
function _M.getGroupUserByUidGid(uid,gid)
	local sql = "select id,user_id,group_id,create_time,status,role,score,nickname,intro,is_black,"..
	"openid,quit_time,invite_user_id from group_user where user_id=%d and group_id=%d and status=1"
	sql = string.format(sql,uid,gid)
	return mysql_util.query(sql)
end


function _M.getGroupBlackByUidGid(uid,gid)
	local sql = "select id,user_id,group_id,create_time,status,role "..
	"from group_black where user_id=%d and group_id=%d and status=1"
	sql = string.format(sql,uid,gid)
	return mysql_util.query(sql)
end




return _M



