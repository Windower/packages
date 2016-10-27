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
    return s1:copy():union(s2)
end

meta.__mul = function(s1, s2)
    return s1:copy():intersection(s2)
end

meta.__sub = function(s1, s2)
    return s1:copy():difference(s2)
end

meta.__pow = function(s1, s2)
    return s1:copy():symmetric_difference(s2)
end

meta.__tostring = function(s)
    local res = '{'
    for key, el in pairs(s.data) do
        res = res .. tostring(el)
        if next(s.data, key) ~= nil then
            res = res .. ', '
        end
    end
    res = res .. '}'

    return res
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
    t = t or {}

    local s = { data = {} }

    for _, val in pairs(t) do
        s.data[val] = val
    end

    return setmetatable(s, meta)
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

set.add = meta.__add_element

set.remove = meta.__remove_key

set.union = function(s1, s2)
    for el in pairs(s2) do
        s1.data[el] = el
    end

    return s1
end

set.intersection = function(s1, s2)
    for el in pairs(s1) do
        if s2.data[el] == nil then
            s1.data[el] = nil
        end
    end

    return s1
end

set.difference = function(s1, s2)
    for el in pairs(s2) do
        s1.data[el] = nil
    end

    return s1
end

set.symmetric_difference = function(s1, s2)
    for el in pairs(s2) do
        if s1.data[el] ~= nil then
            s1.data[el] = nil
        else
            s1.data[el] = el
        end
    end

    return s1
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

