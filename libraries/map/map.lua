local ffi = require('ffi')
local key_items = require('key_items')
local math = require('math')
local memory = require('memory')
local scanner = require('core.scanner')
local string = require('string')
local target = require('target')
local world = require('world')

ffi.cdef[[
    typedef int (__fastcall *map_fn)(void*, int, float, float, float);
]]

local fn = ffi.cast('map_fn', scanner.scan('&8B542408568D4424108BF18B4C2410508B44240C'))
local this = ffi.cast('void**', scanner.scan('8B7424148B4424108B7C240C8B0D'))[0]

local math_floor = math.floor
local string_char = string.char

local zones = {}
do
    local key_item_offsets = {
        [0] = 384,
        [1] = 1855,
        [2] = 2301,
    }

    local ptr = memory.map_table.ptr
    local i = 0
    while true do
        local entry = ptr[i]
        if entry.zone_id <= 0 then
            break
        end

        local zone = zones[entry.zone_id]
        if not zone then
            zone = {}
            zones[entry.zone_id] = zone
        end
        zone[entry.map_id] = entry
        zone.key_item_offset = key_item_offsets[entry.key_item_offset]
        zone.key_item_index = entry.key_item_index

        i = i + 1
    end
end

return {
    available = function(zone_id)
        local zone = zones[zone_id or world.zone_id]
        return key_items[zone.key_item_offset + zone.key_item_index].available
    end,
    coordinates = function(x, y, z)
        if y == nil then
            local entity = x or target.me
            local pos = entity.position
            x, y, z = pos.x, pos.y, pos.z
        end

        local map_id = fn(this, 0, x, z, y)
        local maps = zones[world.zone_id]
        local entry = maps[map_id]

        return
            x * entry.scale / 1200 - entry.offset_x / 240 - 16 / 15,
            -y * entry.scale / 1200 - entry.offset_y / 240 - 16 / 15,
            map_id
    end,
    position = function(x, y, z)
        if y == nil then
            local entity = x or target.me
            local pos = entity.position
            x, y, z = pos.x, pos.y, pos.z
        end

        local map_id = fn(this, 0, x, z, y)
        local maps = zones[world.zone_id]
        local entry = maps[map_id]

        local x_pos = x * entry.scale / 160 - entry.offset_x / 32 + 0.5
        local y_pos = -y * entry.scale / 160 - entry.offset_y / 32 + 0.5

        return '(' .. string_char(x_pos + 0x40) .. '-' .. tostring(math_floor(y_pos)) .. ')'
    end,
}

--[[
Copyright © 2019, Windower Dev Team
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
