local _M = {}

local cjson = require "cjson.safe"
local parser = require "resty.multipart.parser"

function _M.getArgs()
    local request_method = ngx.var.request_method
    local args = ngx.req.get_uri_args()

    if "POST" == request_method then
        ngx.req.read_body()

        local req_headers = ngx.req.get_headers()
        local req_type = req_headers['content-type']
        ngx.say(req_type)
        if req_type == "application/x-www-form-urlencoded" then
                
            local postArgs = ngx.req.get_post_args()
            --local postArgs = ngx.req.get_body_data()
            if postArgs then
                for k,v in pairs(postArgs) do
                    args[k] = v
                end
            end
        elseif string.sub(req_type,1,20) == "multipart/form-data;" then

            local body = ngx.req.get_body_data()
            local p, err = parser.new(body, ngx.var.http_content_type)
            if not p then
                ngx.say("failed to create parser: ", err)
                return
            end

            while true do
                local part_body, name, mime, filename = p:parse_part()
                if not part_body then
                    break
                end
                args[name] = part_body
            end

        else

            args = ngx.req.get_body_data()
        end



    end
    return args
end

return _M
