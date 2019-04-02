
local tool = require("tool")


local json = require "cjson.safe"


local _M = {}


function _M.valid_session_key(args)


    local is_empty_args = tool.table_is_empty(args)

    if is_empty_args == true then
        return false
    end


    local is_key_exists = tool.key_exists("third_session_id",args)

    if not is_key_exists then
        return false
    end


    --ngx.say(args["third_session_id"])


    if args["third_session_id"] == nil then
        return false
    end



    if args["third_session_id"] == "" then
        return false
    end


    if args["third_session_id"] == true then
        return false
    end


    if args["third_session_id"] == "undefined" then
        return false
    end

    return true
end


function _M.valid_param(args,key)


    local is_empty_args = tool.table_is_empty(args)

    if is_empty_args == true then
        return false
    end


    local is_key_exists = tool.key_exists(key,args)

    if not is_key_exists then
        return false
    end


    --ngx.say(args["third_session_id"])


    if args[key] == nil then
        return false
    end



    if args[key] == "" then
        return false
    end


    if args[key] == true then
        return false
    end


    if args[key] == "undefined" then
        return false
    end

    return true
end




return _M
