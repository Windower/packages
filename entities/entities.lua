local memory = require('memory')
local bit = require('bit')

local entities = {}

local array_size = 0x900

local mob_begin = 0x000
local player_begin = 0x400
local ally_begin = 0x700

entities.get_by_id = function(id)
    if bit.band(id, 0xFF000000) ~= 0 then
        local sub_mask = bit.band(id, 0x7FF)
        local index = sub_mask + (bit.band(id, 0x800) ~= 0 and ally_begin or 0)
        if index < 0 or index > array_size then
            return nil
        end

        local entity = memory.entities[index]
        if entity == nil or entity.id ~= id then
            return nil
        end

        return entity
    end

    for i = player_begin, ally_begin - 1 do
        local entity = memory.entities[i]
        if entity ~= nil and entity.id == id then
            return entity
        end
    end

    return nil
end

entities.get_by_name = function(name)
    for i = 0, array_size do
        local entity = memory.entities[i]
        if entity ~= nil and entity.name == name then
            return entity
        end
    end
end

return setmetatable(entities, {
    __index = function(_, key)
        if type(key) ~= 'number' or key < 0 or key > array_size then
            return nil
        end

        local entity = memory.entities[key]
        return entity ~= nil and entity or nil
    end,
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
