require('table')
local clear = require('table.clear')

local meta = {}

local index = function(q, i)
    return i > 0 and q.index + i or i < 0 and q.index + q.length + i + 1
end

local start = 1000000

-- Metatable

meta.__index = function(q, k)
    local length = q.length
    local i = k > 0 and k or length + k + 1
    if i < 1 or i > length then
        error('Index out of bounds: ' .. tostring(k) .. '/' .. tostring(length), 2)
    end

    return rawget(q, q.index + i)
end

meta.__eq = function(q1, q2)
    local length1 = q1.length
    if length1 ~= q2.length then
        return false
    end

    local index1 = q1.index
    local index2 = q2.index

    for base = 1, length1 do
        if rawget(q1, index1 + base) ~= rawget(q2, index2 + base) then
            return false
        end
    end

    return true
end

meta.__concat = function(q1, q2)
    local length1 = q1.length
    local length2 = q2.length

    local index1 = q1.index
    local index2 = q2.index

    local q = {}

    for base = 1, length1 do
        q[start + base] = rawget(q1, index1 + base)
    end

    for base = 1, length2 do
        q[start + base + length1] = rawget(q2, index2 + base)
    end

    q.length = length1 + length2
    q.index = start

    return setmetatable(q, meta)
end

meta.__len = function(q)
    return q.length
end

meta.__tostring = function(q)
    local length = q.length
    if length == 0 then
        return '<>'
    end

    local i = q.index
    local str = tostring(rawget(q, i + 1))

    for key = 2, length do
        str = str .. ', ' .. tostring(rawget(q, i + key))
    end

    return '<' .. str .. '>'
end

meta.__ipairs = pairs

-- Enumerable base

meta.__pairs = function(q)
    local i = q.index
    local max = i + q.length
    return function(q, k)
        k = k + 1
        if k > max then
            return nil, nil
        end

        return k, rawget(q, k)
    end, q, i
end

meta.__create = function(...)
    local length = select('#', ...)

    local q = {}
    for i = 1, length do
        q[start + i] = select(i, ...)
    end

    q.length = length
    q.index = start

    return setmetatable(q, meta)
end

meta.__convert = function(t)
    local q = {}
    local key = start
    for _, el in pairs(t) do
        key = key + 1
        q[key] = el
    end

    q.length = key
    q.index = start

    return setmetatable(q, meta)
end

meta.__add_element = function(q, el)
    local new_length = q.length + 1
    q.length = new_length
    q[q.index + new_length] = el
end

meta.__remove_key = function(q, i)
    i = index(q, i)

    local length = q.length
    local index = q.index
    local element = rawget(q, i)

    local new_length = length - 1
    for key = i, index + new_length do
        q[key] = rawget(q, key + 1)
    end

    q[index + length] = nil

    q.length = new_length

    return element
end

-- Enumerable overrides

local queue = {}

queue.clear = function(q)
    clear(q)
    rawset(q, 'length', 0)
    rawset(q, 'index', start)
end

-- Unique members

queue.push = function(q, el)
    local new_length = q.length + 1

    q[q.index + new_length] = el
    q.length = new_length
end

queue.pop = function(q)
    local new_index = q.index + 1
    local el = q[new_index]

    q[new_index] = nil
    q.length = q.length - 1
    q.index = new_index

    return el
end

-- Invoke enumerable library

local enumerable = require('enumerable')
return enumerable.init_type(meta, queue, 'queue')

--[[
Copyright © 2018, Windower Dev Team
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this queue of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this queue of conditions and the following disclaimer in the
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
