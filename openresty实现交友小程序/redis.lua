local redisConfig = require"redis_config"
local redis = require("resty.redis")

local redis_pool = {}

--[[
    先从连接池取连接,如果没有再建立连接.
    返回:
        false,出错信息.
        true,redis连接
--]]
function redis_pool:get_connect()
    if ngx.ctx[redis_pool] then
        return true, ngx.ctx[redis_pool]
    end

    local client, errmsg = redis:new()
    if not client then
        return false, "redis.socket_failed: " .. (errmsg or "nil")
    end

    client:set_timeout(1000)  --10秒

    local result, errmsg = client:connect(redisConfig.REDIS_HOST, redisConfig.REDIS_PORT)
    if not result then
        return false, errmsg
    end

    ngx.ctx[redis_pool] = client
    return true, ngx.ctx[redis_pool]
end

function redis_pool:close()
    if ngx.ctx[redis_pool] then
        ngx.ctx[redis_pool]:set_keepalive(10000, 100)
        ngx.ctx[redis_pool] = nil
    end
end

return redis_pool
