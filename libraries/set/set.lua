local meta = {}

-- Metatable

meta.__index = function(_, _)
    error('Cannot access set index.')
end

meta.__newindex = function(_, _, _)
    error('Cannot assign to set indices.')
end

meta.__eq = function(s1, s2)
    local data1 = s1.data
    local data2 = s2.data

    for el in pairs(data1) do
        if data2[el] == nil then
            return false
        end
    end

    for el in pairs(data2) do
        if data1[el] == nil then
            return false
        end
    end

    return true
end

meta.__le = function(s1, s2)
    local data1 = s1.data
    local data2 = s2.data

    for el in pairs(data1) do
        if data2[el] == nil then
            return false
        end
    end

    return true
end

meta.__lt = function(s1, s2)
    local data1 = s1.data
    local data2 = s2.data

    for el in pairs(data1) do
        if data2[el] == nil then
            return false
        end
    end

    for el in pairs(data2) do
        if data1[el] == nil then
            return true
        end
    end

    return false
end

meta.__add = function(s1, s2)
    local data = {}

    local data1 = s1.data
    local data2 = s2.data

    for el in pairs(data1) do
        data[el] = el
    end

    for el in pairs(data2) do
        data[el] = el
    end

    return setmetatable({ data = data }, meta)
end

meta.__mul = function(s1, s2)
    local data = {}

    local data1 = s1.data
    local data2 = s2.data

    for el in pairs(data1) do
        if data2[el] ~= nil then
            data[el] = el
        end
    end

    return setmetatable({ data = data }, meta)
end

meta.__sub = function(s1, s2)
    local data = {}

    local data1 = s1.data
    local data2 = s2.data

    for el in pairs(data1) do
        if data2[el] == nil then
            data[el] = el
        end
    end

    return setmetatable({ data = data }, meta)
end

meta.__pow = function(s1, s2)
    local data = {}

    local data1 = s1.data
    local data2 = s2.data

    for el in pairs(data1) do
        if data2[el] == nil then
            data[el] = el
        end
    end

    for el in pairs(data2) do
        if data1[el] == nil then
            data[el] = el
        end
    end

    return setmetatable({ data = data }, meta)
end

meta.__tostring = function(s)
    local data = s.data
    local el = next(data)
    if el == nil then
        return '{}'
    end

    local res = tostring(el)

    el = next(data, el)
    while el ~= nil do
        res = res .. ', ' .. tostring(el)
        el = next(data, el)
    end

    return '{' .. res .. '}'
end

meta.__ipairs = function(s)
    error('ipairs not defined for sets.')
end

-- Enumerable base

meta.__pairs = function(s)
    return next, s.data, nil
end

meta.__create = function(...)
    local data = {}
    for i = 1, select('#', ...) do
        local el = select(i, ...)
        data[el] = el
    end
    return setmetatable({ data = data }, meta)
end

meta.__convert = function(t)
    local data = {}
    for _, el in pairs(t) do
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

local set = {}

set.contains = function(s, el)
    return s.data[el] == el
end

-- Unique members

set.union = function(s1, s2)
    local data1 = s1.data
    local data2 = s2.data

    for el in pairs(data2) do
        data1[el] = el
    end
end

set.intersection = function(s1, s2)
    local data1 = s1.data
    local data2 = s2.data

    for el in pairs(data1) do
        if data2[el] == nil then
            data1[el] = nil
        end
    end
end

set.difference = function(s1, s2)
    local data1 = s1.data
    local data2 = s2.data

    for el in pairs(data2) do
        data1[el] = nil
    end
end

set.symmetric_difference = function(s1, s2)
    local data1 = s1.data
    local data2 = s2.data

    for el in pairs(data2) do
        data1[el] = data1[el] == nil and el or nil
    end
end

-- Invoke enumerable library

local enumerable = require('enumerable')
return enumerable.init_type(meta, set, 'set')

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
