local memory = require('memory')
local bit = require('bit')

local array = memory.entities

local by_id
do
    local bit_band = bit.band

    by_id = function(id, min, max)
        if bit_band(id, 0xFF000000) ~= 0 then
            local sub_mask = bit_band(id, 0x7FF)
            local index = sub_mask + (bit_band(id, 0x800) ~= 0 and 0x700 or 0)
            if index < min or index > max then
                return nil
            end

            local entity = array[index]
            if entity == nil or entity.id ~= id then
                return nil
            end

            return entity
        end

        for i = min, max - 1 do
            local entity = array[i]
            if entity ~= nil and entity.id == id then
                return entity
            end
        end

        return nil
    end
end

local by_name = function(name, min, max)
    for i = min, max - 1 do
        local entity = array[i]
        if entity ~= nil and entity.name == name then
            return entity
        end
    end

    return nil
end

local index = function(key, min, max)
    if type(key) ~= 'number' or key < min or key > max - 1 then
        return nil
    end

    local entity = array[key]
    return entity ~= nil and entity or nil
end

local iterator = function(min, max)
    return function(t, k)
        k = k + 1
        if k > max - 1 then
            return nil, nil
        end

        local entity = t[k]
        return k, entity ~= nil and entity or nil
    end, array, min - 1
end

local build_table = function(min, max, t)
    t = t or {}

    t.by_id = function(_, id)
        return by_id(id, min, max)
    end

    t.by_name = function(_, name)
        return by_name(name, min, max)
    end

    return setmetatable(t, {
        __index = function(_, k)
            return index(k, min, max)
        end,
        __pairs = function(_)
            return iterator(min, max)
        end,
        __ipairs = pairs,
        __newindex = error,
        __metatable = false,
    })
end

return build_table(0x000, 0x900, {
    npcs = build_table(0x000, 0x400),
    pcs = build_table(0x400, 0x700),
    allies = build_table(0x700, 0x900),
})

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
