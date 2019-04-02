local mysql_pool = require("mysql_master_pool")


local _M = {}


function _M.query(sql)

    local ret, res, _ = mysql_pool:query(sql)
    if not ret then
        ngx.log(ngx.ERR, "query db error. res: " .. (res or "nil"))
        return nil
    end

    return res
end

function _M.execute(sql)

    local ret, res, sqlstate = mysql_pool:query(sql)
    if not ret then
        ngx.log(ngx.ERR, "mysql.execute_failed. res: " .. (res or 'nil') .. ",sql_state: " .. (sqlstate or 'nil'))
        return -1
    end

    return res.affected_rows
end

return _M
