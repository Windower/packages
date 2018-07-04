local bit = require('bit')
local os = require('os')
local pack   = require('pack')
local packets = require('packets')
local shared = require('shared')

status_effects = shared.new('status_effects')

status_effects.env = {
    next = next,
}

status_effects.data = {
    player = {},
    party = {},
}

packets.incoming:register_init({
    [{0x063, 9}] = function(p)
        for i = 1, 0x20 do
            local buff_id = p.status_effects[i - 1]
            if buff_id == 0 or buff_id == 0xFF then
                status_effects.data.player[i] = nil
            else
                status_effects.data.player[i] = {
                    id = buff_id,
                    timestamp = (p.durations[i - 1] / 60) + 501079520 + 1009810800 - os.time()
                }
            end
        end
    end,

    [{0x076}] = function(p)
        local data = status_effects.data.party
        for i = 0, 4 do
            v = p.party_members[i]
            if v.id ~= 0 then
                data[i + 1] = {}
                for pos = 0, 0x1F do
                    local base_value = v.status_effects[pos]
                    local mask_index = bit.rshift((pos), 2)
                    local mask_offset = 2 * (pos % 4)
                    local mask_value = bit.rshift(v.status_effect_mask:byte(mask_index + 1), mask_offset) % 4
                    local temp = base_value + 0x100 * mask_value
                    if temp ~= 0xFF then
                        data[i + 1][pos] = temp
                    end
                end
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
