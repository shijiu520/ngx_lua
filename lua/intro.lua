--local logger = require "resty.logger"
--local log = logger:new('debug', '/opt/log/logfile.log' )
local common = require("common")
local mysql_util = require("mysql_util")
local tool = require("tool")
local json = require "cjson.safe"





local sql = "select * from activity_set order by id desc limit 1"
local row = mysql_util.query(sql)

--ngx.say(row[1]["rule"])




local data = {}

data["share_title"] = row[1]["share_title"]
data["name"] = row[1]["activity_name"]
data["intro"] = row[1]["intro"]
--data["rule"] = tool.string_split(row[1]["rule"],"\n")
data["rule"] = tool.splitStr(row[1]["rule"],"\r\n")
--data["rule"] = row[1]["rule"]





tool.toJson(0,"获取成功",data)

