local tool = require("tool")
local mongo = require 'resty.mongol'

local conn = mongo:new()
conn:set_timeout(2000)
local ok,err = conn:connect('120.79.204.91',27017)

if not ok then
    ngx.say("connect failed: " .. err)
end

local db = conn:new_db_handle("kankan")

local col = db:get_col("video")


local r = col:find({status=1,is_delete=0})                                                                                                                                                         


r:limit(5)

ret,err = r:sort({sort=1})

for k,v in pairs(ret) do
    --ngx.say(v["_id"]:tostring())
    ret[k]["id"] = v["_id"]:tostring()
    ret[k]["_id"] = nil
end






tool.toJson(0,"SUCCESS",ret)
