local list = {}
local meta = {}

local make_key = function(l, k)
    if type(k) ~= 'number' then
        return nil
    end

    k = k < 0 and l.count + k + 1 or k
    if k < 1 or k > l.count then
        error('Index outside of list range (' .. tostring(k) .. '/' .. tostring(l.count) .. ').')
    end

    return k
end

-- Metatable

meta.__index = function(l, k)
    if type(k) == 'string' then
        return list[k]
    end

    local key = make_key(l, k)
    if key == nil then
        return nil
    end

    return rawget(l, key)
end

meta.__newindex = function(l, k, v)
    local key = make_key(l, k)
    if key == nil then
        return
    end

    rawset(l, key, v)
end

meta.__eq = function(l1, l2)
    if l1.count ~= l2.count then
        return false
    end

    for key = 1, l1.count do
        if rawget(l1, key) ~= rawget(l2, key) then
            return false
        end
    end

    return true
end

meta.__concat = function(l1, l2)
    local res = l1:copy()
    res:extend(l2)
    return res
end

meta.__tostring = function(l)
    local str = '['

    for key = 1, l.count do
        if key > 1 then
            str = str .. ', '
        end
        str = str .. tostring(rawget(l, key))
    end

    return str .. ']'
end

meta.__ipairs = pairs

meta.__metatable = false

-- Enumerable base

meta.__pairs = function(l)
    local key = 0
    return function(l, k)
        key = key + 1
        if key > l.count then
            return nil
        end

        return key, rawget(l, key)
    end, l, nil
end

meta.__create = function(t)
    t = t or {}

    local l = {}

    local index = 0
    for _, el in pairs(t) do
        index = index + 1
        l[index] = el
    end

    l.count = index
    return setmetatable(l, meta)
end

meta.__add_element = function(l, el)
    l.count = l.count + 1
    rawset(l, l.count, el)
end

meta.__remove_key = function(l, i)
    i = make_key(l, i)
    local el = rawget(l, i)

    for key = i, l.count do
        rawset(l, key, rawget(l, key + 1))
    end
    l.count = l.count - 1

    return el
end

-- Enumerable overrides

list.length = function(l)
    return l.count
end

list.clear = function(l)
    l.count = 0
end

-- Unique members

list.add = meta.__add_element

list.remove = meta.__remove_key

list.insert = function(l, i, el)
    i = make_key(l, i)

    l.count = l.count + 1
    for key = i, l.count do
        local next = el
        el = rawget(l, key)
        rawset(l, key, next)
    end
end

list.remove_element = function(l, el)
    for key = 1, l.count do
        if rawget(l, key) == el then
            l:remove(key)
            break
        end
    end
end

list.extend = function(l1, l2)
    for k = 1, l2.count do
        rawset(l1, l1.count + k, rawget(l2, k))
    end

    l1.count = l1.count + l2.count
end

-- Invoke enumerable library

require('enumerable')(meta)

return meta.__create

--[[
Copyright © 2016, Windower
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of Windower nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Windower BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

