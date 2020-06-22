local bit = require('bit')
local event = require('core.event')
local ffi = require('ffi')
local os = require('os')
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
    array               = {struct.struct({
        id                  = {struct.int32},
        _duration_end       = {struct.double},
    })[0x20]},
    gained              = {data = event.new()},
    lost                = {data = event.new()},
}))

local data_player = data.party[0]
local data_party = data.party
local data_array = data.array
local event_gained = data.gained
local event_lost = data.lost

local bit_band = bit.band
local bit_rshift = bit.rshift
local ffi_copy = ffi.copy
local ffi_fill = ffi.fill
local os_clock = os.clock
local string_byte = string.byte

for i = 0, 0x1F do
    data_array[i].id = 0xFF
end

local last_tick = 0
local last_clock = 0
local packet_buffer = struct.new(packet.incoming[0x063][0x09].type)

local calculate_diff
local process_effects
do
    do
        local temp_buffer = struct.new(struct.int8[status_effects_size])

        calculate_diff = function(source, destination)
            local gained = {}
            local gained_count = 0
            local lost = {}
            local lost_count = 0

            ffi_fill(temp_buffer, status_effects_size)

            for i = 0, 0x1F do
                local status_effect = source[i]
                if status_effect ~= 0xFF then
                    temp_buffer[status_effect] = temp_buffer[status_effect] + 1
                end
            end

            for i = 0, status_effects_size - 1 do
                local array_count = temp_buffer[i]
                local data_count = destination[i]

                for _ = 1, array_count - data_count do
                    gained_count = gained_count + 1
                    gained[gained_count] = i
                end

                for _ = 1, data_count - array_count do
                    lost_count = lost_count + 1
                    lost[lost_count] = i
                end

                destination[i] = array_count
            end

            return gained, lost
        end
    end

    local update_data
    do
        local status_effects = packet_buffer.status_effects
        local end_ticks = packet_buffer.end_ticks

        update_data = function()
            for i = 0, 0x1F do
                local entry = data_array[i]
                entry.id = status_effects[i]
                local end_tick = end_ticks[i]
                if end_tick ~= 0 then
                    entry._duration_end = last_clock + (end_tick - last_tick) / 60
                else
                    entry._duration_end = 0
                end
            end
        end
    end

    do
        local data_effects = data_player.effects
        local status_effects = packet_buffer.status_effects

        process_effects = function()
            local gained, lost = calculate_diff(status_effects, data_effects)

            update_data()

            if #gained > 0 then
                event_gained:trigger(0, unpack(gained))
            end

            if #lost > 0 then
                event_lost:trigger(0, unpack(lost))
            end
        end
    end
end

local party_buff_array = struct.new(struct.int32[0x20])

packet.incoming:register_init({
    [{0x00A}] = function(p)
        data_player.id = p.player_id
        data_player.index = p.player_index
    end,

    [{0x037}] = function(p)
        last_tick = (p.home_point_timestamp * 60 - p.home_point_ticks) % 2^32
        last_clock = os_clock()
        process_effects()
    end,

    [{0x063, 9}] = function(p, info)
        ffi_copy(packet_buffer, p, info.modified_size)
        process_effects()
    end,

    [{0x076}] = function(p)
        for i = 1, 5 do
            local data_party_member = data_party[i]
            local party_member = p.party_members[i - 1]

            local party_member_id = party_member.id
            local trigger = data_party_member.id == party_member_id
            data_party_member.id = party_member_id
            data_party_member.index = party_member.index

            if party_member_id ~= 0 then
                local high_bit_mask = party_member.status_effect_mask
                local status_effects = party_member.status_effects

                for j = 0, 0x1F do
                    local low_value = status_effects[j]
                    local high_value = bit_band(bit_rshift(string_byte(high_bit_mask, j / 4 + 1), bit_band(j * 2, 7)), 3)
                    party_buff_array[j] = high_value * 0x100 + low_value
                end

                local gained, lost = calculate_diff(party_buff_array, data_party_member.effects)

                if trigger then
                    if #gained > 0 then
                        event_gained:trigger(i, unpack(gained))
                    end

                    if #lost > 0 then
                        event_lost:trigger(i, unpack(lost))
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
