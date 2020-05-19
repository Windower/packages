local bit = require('bit')
local event = require('core.event')
local ffi = require('ffi')
local packet = require('packet')
local server = require('shared.server')
local string = require('string')
local struct = require('struct')

local status_effects_size = 0x400

local data = server.new(struct.struct({
    party               = {struct.struct({
        id                  = {struct.int32},
        index               = {struct.int32},
        effects             = {struct.int8[status_effects_size]},
    })[6]},
    durations           = {struct.struct({
        id                  = {struct.int32},
        timestamp           = {struct.time()},
    })[0x20]},
    status_effect_gained         = {data=event.new()},
    status_effect_lost           = {data=event.new()},
}))

local data_player = data.party[0]
local data_party = data.party
local data_durations = data.durations
local event_status_effect_gained = data.status_effect_gained
local event_status_effect_lost = data.status_effect_lost

local temp_buffer = struct.new(struct.int8[status_effects_size])
local temp_array = struct.new(struct.int32[0x20])

local bit_band = bit.band
local bit_rshift = bit.rshift
local ffi_fill = ffi.fill
local string_byte = string.byte

local process_effects = function(effects_array, data_effects)
    local gained = {}
    local gained_count = 0
    local lost = {}
    local lost_count = 0

    ffi_fill(temp_buffer, status_effects_size)

    for i = 0, 0x1F do
        local status_effect = effects_array[i]
        if status_effect ~= 0xFF then
            temp_buffer[status_effect] = temp_buffer[status_effect] + 1
        end
    end

    for i = 0, status_effects_size - 1 do
        local array_count = temp_buffer[i]
        local data_count = data_effects[i]

        for _ = 1, array_count - data_count do
            gained_count = gained_count + 1
            gained[gained_count] = i
        end

        for _ = 1, data_count - array_count do
            lost_count = lost_count + 1
            lost[lost_count] = i
        end

        data_effects[i] = array_count
    end

    return gained, lost
end

packet.incoming:register_init({
    [{0x00A}] = function(p)
        data_player.id = p.player_id
        data_player.index = p.player_index
    end,

    [{0x063, 9}] = function(p)
        local status_effects = p.status_effects
        if status_effects[0] == 0 and status_effects[1] == 0 then
            return
        end

        local gained, lost = process_effects(status_effects, data_player.effects)

        local durations = p.durations
        for i = 0, 0x1F do
            local slot = data_durations[i]
            slot.id = status_effects[i]
            slot.timestamp = durations[i]
        end

        if gained[1] then
            event_status_effect_gained:trigger(0, unpack(gained))
        end

        if lost[1] then
            event_status_effect_lost:trigger(0, unpack(lost))
        end
    end,

    [{0x076}] = function(p)
        for i = 0, 4 do
            local data_party_member = data_party[i + 1]
            local party_member = p.party_members[i]

            local party_member_id = party_member.id
            local trigger = data_party_member.id == party_member_id
            data_party_member.id = party_member.id
            data_party_member.index = party_member.index

            if party_member.id ~= 0 then
                local high_bit_mask = party_member.status_effect_mask
                local status_effects = party_member.status_effects

                for j = 0, 0x1F do
                    local low_value = status_effects[j]
                    local high_value = bit_band(bit_rshift(string_byte(high_bit_mask, j / 4 + 1), bit_band(j * 2, 7)), 3)
                    temp_array[j] = high_value * 0x100 + low_value
                end

                local gained, lost = process_effects(temp_array, data_party_member.effects)

                if trigger then
                    if gained[1] then
                        event_status_effect_gained:trigger(i, unpack(gained))
                    end

                    if lost[1] then
                        event_status_effect_lost:trigger(i, unpack(lost))
                    end
                end
            else
                ffi_fill(data_party_member, status_effects_size)
            end
        end
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
