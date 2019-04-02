local _M = {}


local json = require "cjson.safe"
local random = math.random
local randomseed = math.randomseed
local time = os.time

function _M.toJson(code,msg,data) 
    local arr = {}

    arr["errorCode"] = code
    arr["errorMsg"] = msg
    data = data or {}
    arr["data"] = data
    
    ngx.say(json.encode(arr))
    return

end

function _M.toJson2(code,msg,data,totalPage) 
    local arr = {}

    arr["errorCode"] = code
    arr["errorMsg"] = msg
    data = data or {}
    arr["data"] = data
    arr["totalPage"] = totalPage
    ngx.say(json.encode(arr))
    return

end

--判断数组是否为空
function _M.table_is_empty(t)

    return t==nil or _G.next( t ) == nil

end

function _M.in_array(value, tbl)
  for k,v in ipairs(tbl) do
    if v == value then
      return true;
    end
  end
  return false;
end



--随机打乱数组
function _M.shuffle(tbl)
    local n = #tbl
    for i = 1, n do
        randomseed(tostring(time()):reverse():sub(1, 6))
        local j = random(i, n)
        if j > i then
            tbl[i], tbl[j] = tbl[j], tbl[i]
        end
    end
end


--字符串分割成数组
function _M.Split(szFullString, szSeparator)
    local nFindStartIndex = 1
    local nSplitIndex = 1
    local nSplitArray = {}
    while true do
        local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
        if not nFindLastIndex then
            nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
            break
        end
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
        nFindStartIndex = nFindLastIndex + string.len(szSeparator)
        nSplitIndex = nSplitIndex + 1
    end
    return nSplitArray
end


function _M.split2(str,det)
    splitlist = {}
    string.gsub(str, det, function(w) table.insert(splitlist, w) end )
    return splitlist

end




function _M.string_split(str, split_char)
    local sub_str_tab = {};
    while (true) do
        local pos = string.find(str, split_char);
        if (not pos) then
            sub_str_tab[#sub_str_tab + 1] = str;
            break;
        end
        local sub_str = string.sub(str, 1, pos - 1);
        sub_str_tab[#sub_str_tab + 1] = sub_str;
        str = string.sub(str, pos + 1, #str);
    end
 
    return sub_str_tab;
end


--字符串分割 
function _M.splitStr(content, token)
    if not content or not token then return end
    local strArray = {}
    local i = 1
    local contentLen = string.len(content)
    while true do
        -- true是用来避开string.find函数对特殊字符检查 特殊字符 "^$*+?.([%-"
        local beginPos, endPos = string.find(content, token, 1, true) 
        if not beginPos then
            strArray[i] = string.sub(content, 1, contentLen)
            break
        end
        strArray[i] = string.sub(content, 1, beginPos-1)
        content = string.sub(content, endPos+1, contentLen)
        contentLen = contentLen - endPos
        i = i + 1
    end
    return strArray
end



function _M.key_exists(key, tab)
    for k,v in pairs(tab) do
      if k == key then
          return true
      end
    end
    return false
end





function _M.day_step(old_day,step) 
   local y,m,d
   if("0" ~= string.sub(old_day,6,6)) then
      m=string.sub(old_day,6,7)
   else
      m=string.sub(old_day,7,7)
   end

   if("0" ~= string.sub(old_day,9,9)) then
      d=string.sub(old_day,9,10)
   else
      d=string.sub(old_day,10,10)
   end

   y=string.sub(old_day,0,4)
   
   local old_time=os.time{year=y,month=m,day=d}
   local new_time=old_time+86400*step

   local new_day=os.date("*t",new_time)
   local res=""

   if(tonumber(new_day.day)<10 and tonumber(new_day.month)<10)then
      res=new_day.year.."-".."0"..new_day.month.."-".."0"..new_day.day
   elseif tonumber(new_day.month)<10 then
      res=new_day.year.."-".."0"..new_day.month.."-"..new_day.day
   
   elseif tonumber(new_day.day)<10 then
      res=new_day.year.."-"..new_day.month.."-".."0"..new_day.day
   else
      res=new_day.year.."-"..new_day.month.."-"..new_day.day
   end
   return res
end

function _M.filter_spec_chars(s)
    local ss = {}
    local k = 1
    while true do
        if k > #s then break end
        local c = string.byte(s,k)
        if not c then break end
        if c<192 then
            if (c>=48 and c<=57) or (c>= 65 and c<=90) or (c>=97 and c<=122) then
                table.insert(ss, string.char(c))
            end
            k = k + 1
        elseif c<224 then
            k = k + 2
        elseif c<240 then
            if c>=228 and c<=233 then
                local c1 = string.byte(s,k+1)
                local c2 = string.byte(s,k+2)
                if c1 and c2 then
                    local a1,a2,a3,a4 = 128,191,128,191
                    if c == 228 then a1 = 184
                    elseif c == 233 then a2,a4 = 190,c1 ~= 190 and 191 or 165
                    end
                    if c1>=a1 and c1<=a2 and c2>=a3 and c2<=a4 then
                        table.insert(ss, string.char(c,c1,c2))
                    end
                end
            end
            k = k + 3
        elseif c<248 then
            k = k + 4
        elseif c<252 then
            k = k + 5
        elseif c<254 then
            k = k + 6
        end
    end
    return table.concat(ss)
end



return _M

