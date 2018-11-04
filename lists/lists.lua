local list = {}
local meta = {}

local make_key = function(l, k)
    assert(type(k) == 'number', 'Invalid index ' .. tostring(k))

    local length = l.length
    k = k < 0 and length + k + 1 or k
    assert(k >= 0 and k <= length, 'Invalid index ' .. tostring(k))

    return k
end

-- Metatable

meta.__index = function(l, k)
    if type(k) == 'string' then
        return list[k]
    end

    return rawget(l, make_key(l, k))
end

meta.__newindex = function(l, k, v)
    rawset(l, make_key(l, k), v)
end

meta.__eq = function(l1, l2)
    local length1 = l1.length
    if length1 ~= l2.length then
        return false
    end

    for key = 1, length1 do
        if rawget(l1, key) ~= rawget(l2, key) then
            return false
        end
    end

    return true
end

meta.__concat = function(l1, l2)
    local res = l1:copy()
    res:append(l2)
    return res
end

meta.__len = function(l)
    return l.length
end

meta.__tostring = function(l)
    local str = ''

    for key = 1, l.length do
        if key > 1 then
            str = str .. ', '
        end
        str = str .. tostring(rawget(l, key))
    end

    return '[' .. str .. ']'
end

meta.__ipairs = pairs

meta.__metatable = false

-- Enumerable base

meta.__pairs = function(l)
    local key = 0
    return function(l, k)
        key = key + 1
        if key > l.length then
            return nil
        end

        return key, rawget(l, key)
    end, l, nil
end

meta.__create = function(t)
    local l = { length = 0 }
    local key = 0
    for _, el in pairs(t or {}) do
        key = key + 1
        l[key] = el
    end
    l.length = key
    return setmetatable(l, meta)
end

meta.__add_element = function(l, el)
    local new_length = l.length + 1
    l.length = new_length
    rawset(l, new_length, el)
end

meta.__remove_key = function(l, i)
    local index = make_key(l, i)
    local el = rawget(l, index)

    local length = l.length
    for key = index, length do
        rawset(l, key, rawget(l, key + 1))
    end
    l.length = length - 1

    return el
end

-- Enumerable overrides

list.clear = function(l)
    l.length = 0
end

list.first = function(l)
    return rawget(l, 1)
end

list.last = function(l)
    return rawget(l, l.length)
end

list.element_at = function(l, index)
    return rawget(l, index)
end

-- Unique members

list.insert = function(l, i, el)
    local length = l.length

    l.length = length + 1
    local index = make_key(l, i)

    local current = el
    for key = index, length do
        local next = current
        current = rawget(l, key)
        rawset(l, key, next)
    end
end

list.remove_element = function(l, el)
    for key = 1, l.length do
        if rawget(l, key) == el then
            l:remove(key)
            break
        end
    end
end

list.append = function(l1, l2)
    local length1 = l1.length
    local length2 = l2.length

    for k = 1, length2 do
        rawset(l1, length1 + k, rawget(l2, k))
    end

    l1.length = length1 + length2
end

-- Invoke enumerable library

local enumerable = require('enumerable')
return enumerable.init_type(meta, 'list')

--[[
Copyright © 2018, Windower Dev Team
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Windower Dev Team nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE WINDOWER DEV TEAM BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
