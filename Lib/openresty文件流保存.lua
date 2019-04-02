--基于openresty 实现微信小程序保存外部视频到相册
--以及微信头像保存跨域
--返回文件流
--比php的curl  file_get_contents 性能高效
local http = require "resty.http"
local httpc = http.new()


local args = ngx.req.get_uri_args()

local url = args['url']


if not url then
    ngx.say("没有url")
    return
end



url = ngx.unescape_uri(url)

local res, err = httpc:request_uri(url,{ssl_verify=false})

if not res then
     ngx.say("failed to request: ", err)
     return
end


ngx.header['content-type'] = 'video/mp4'

ngx.print(res.body)
ngx.flush()






