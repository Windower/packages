local set = {}
local meta = {}

-- Metatable

meta.__index = set

meta.__newindex = function(s, k, v)
    error('Cannot assign to set indices.')
end

meta.__eq = function(s1, s2)
    for el in pairs(s1) do
        if not s2.data[el] then
            return false
        end
    end

    for el in pairs(s2) do
        if not s1.data[el] then
            return false
        end
    end

    return true
end

meta.__le = function(s1, s2)
    for el in pairs(s1) do
        if not s2.data[el] then
            return false
        end
    end

    return true
end

meta.__lt = function(s1, s2)
    return s1 <= s2 and s1 ~= s2
end

meta.__add = function(s1, s2)
    local res = s1:copy()
    res:union(s2)
    return res
end

meta.__mul = function(s1, s2)
    local res = s1:copy()
    res:intersection(s2)
    return res
end

meta.__sub = function(s1, s2)
    local res = s1:copy()
    res:difference(s2)
    return res
end

meta.__pow = function(s1, s2)
    local res = s1:copy()
    res:symmetric_difference(s2)
    return res
end

meta.__tostring = function(s)
    local res = ''

    local first = true
    for _, el in pairs(s.data) do
        if first then
            first = false
        else
            res = res .. ', '
        end
        res = res .. tostring(el)
    end

    return '{' .. res .. '}'
end

meta.__ipairs = function(s)
    error('ipairs not defined for sets.')
end

meta.__metatable = false

-- Enumerable base

meta.__pairs = function(s)
    return next, s.data, nil
end

meta.__create = function(t)
    local data = {}
    for _, el in pairs(t or {}) do
        data[el] = el
    end
    return setmetatable({ data = data }, meta)
end

meta.__add_element = function(s, el)
    s.data[el] = el
end

meta.__remove_key = function(s, el)
    s.data[el] = nil
end

-- Enumerable overrides

set.contains = function(s, el)
    return s.data[el] == el
end

-- Unique members

set.union = function(s1, s2)
    for el in pairs(s2) do
        s1.data[el] = el
    end
end

set.intersection = function(s1, s2)
    for el in pairs(s1) do
        if s2.data[el] == nil then
            s1.data[el] = nil
        end
    end
end

set.difference = function(s1, s2)
    for el in pairs(s2) do
        s1.data[el] = nil
    end
end

set.symmetric_difference = function(s1, s2)
    for el in pairs(s2) do
        if s1.data[el] ~= nil then
            s1.data[el] = nil
        else
            s1.data[el] = el
        end
    end
end

-- Invoke enumerable library

local enumerable = require('enumerable')
return enumerable.init_type(meta, 'set')

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
