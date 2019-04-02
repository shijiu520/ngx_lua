local logger = require "resty.logger"
local log = logger:new('debug', '/opt/log/logfile.log' )


local date = os.date

local mysql_util = require("mysql_util")
local tool = require("tool")

--local redisLib = require("redis")
local redisLib = require("360_redis")

local _M = {}

--获取今天是第几天

function _M.getDay() 
    local setSql = "select * from activity_set order by id desc limit 1"
    local set = mysql_util.query(setSql)

    local today = date("%Y-%m-%d",ngx.time())

    local begin = set[1]["begin_timestamp"]
    local ends = set[1]["end_timestamp"]

    local first_day = date("%Y-%m-%d",begin)
    local second_day = date("%Y-%m-%d",begin+86400)
    local third_day = date("%Y-%m-%d",begin+86400*2)
    local four_day = date("%Y-%m-%d",begin+86400*3)


    if today == first_day then
        return 1
    elseif today == second_day then
        return 2
    elseif today == third_day then
        return 3
    elseif today == four_day then
        return 4
    else
        return 5
    end

end


--获取剩余翻牌次数

function _M.get_num(openid)
    --[[    
    local ok,redisConn = redisLib:get_connect()
    if not ok then
        ngx.say("redis server connected failed =================")
        return
    end
    --]]
    
    local redisConn = redisLib:new()



    redisConn:select(7)

    local flop_num = redisConn:hget("hash:flop_num_"..date("%Y%m%d",ngx.time()),openid)
  
    --ngx.say(flop_num)

    if flop_num == ngx.null or flop_num == nil then
        flop_num = 0
    end

    --[[

    local share_num = redisConn:hget("hash:share_"..date("%Y%m%d",ngx.time()),openid)

    if share_num == ngx.null or share_num == nil then
        share_num = 0
    end


    local use_share_num = redisConn:hget("hash:use_share_"..date("%Y%m%d",ngx.time()),openid)

    if use_share_num == ngx.null or use_share_num == nil then
        use_share_num = 0
    end



    local total_num = 10 - tonumber(flop_num) + tonumber(share_num) - tonumber(use_share_num)
    --local total_num = 0
    --]]
    
    local first_key = "hash:first_share_num_"..date("%Y%m%d");
    local second_key = "hash:second_share_num_"..date("%Y%m%d");
    local third_key = "hash:third_share_num_"..date("%Y%m%d");

    local first_share_num = redisConn:hget(first_key,openid);
    local second_share_num = redisConn:hget(second_key,openid);
    local third_share_num = redisConn:hget(third_key,openid);

    
    local use_first_key = "hash:use_first_share_num_"..date("%Y%m%d");
    local use_second_key = "hash:use_second_share_num_"..date("%Y%m%d");
    local use_third_key = "hash:use_third_share_num_"..date("%Y%m%d");

    local use_first_share_num = redisConn:hget(use_first_key,openid);
    local use_second_share_num = redisConn:hget(use_second_key,openid);
    local use_third_share_num = redisConn:hget(use_third_key,openid);


    if first_share_num == ngx.null or first_share_num == nil then
        first_share_num = 0
    end
    
    if second_share_num == ngx.null or second_share_num == nil then
        second_share_num = 0
    end
    
    if third_share_num == ngx.null or third_share_num == nil then
        third_share_num = 0
    end

        
    if use_first_share_num == ngx.null or use_first_share_num == nil then
        use_first_share_num = 0
    end

    if use_second_share_num == ngx.null or use_second_share_num == nil then
        use_second_share_num = 0
    end

    if use_third_share_num == ngx.null or use_third_share_num == nil then
        use_third_share_num = 0
    end

    local total_num = 6 - tonumber(flop_num) + (tonumber(first_share_num)-tonumber(use_first_share_num)) + (tonumber(second_share_num)-tonumber(use_second_share_num)) + (tonumber(third_share_num)-tonumber(use_third_share_num));
 


    return tonumber(total_num)
end


return _M
