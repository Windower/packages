local list = {}
local meta = {}

local make_key = function(l, k)
    assert(type(k) == 'number', 'Invalid index ' .. tostring(k))

    k = k < 0 and l.count + k + 1 or k
    assert(k >= 0 and k <= l.count, 'Invalid index ' .. tostring(k))

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
    res:append(l2)
    return res
end

meta.__tostring = function(l)
    local str = ''

    for key = 1, l.count do
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
        if key > l.count then
            return nil
        end

        return key, rawget(l, key)
    end, l, nil
end

meta.__create = function(t)
    local l = { count = 0 }
    local key = 0
    for _, el in pairs(t or {}) do
        key = key + 1
        l[key] = el
    end
    l.count = key
    return setmetatable(l, meta)
end

meta.__add_element = function(l, el)
    l.count = l.count + 1
    rawset(l, l.count, el)
end

meta.__remove_key = function(l, i)
    local made = make_key(l, i)
    local el = rawget(l, made)

    for key = made, l.count do
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

list.insert = function(l, i, el)
    l.count = l.count + 1
    local made = make_key(l, i)

    for key = made, l.count do
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

list.append = function(l1, l2)
    for k = 1, l2.count do
        rawset(l1, l1.count + k, rawget(l2, k))
    end

    l1.count = l1.count + l2.count
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
