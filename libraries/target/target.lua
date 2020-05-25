local bit = require('bit')
local command = require('core.command')
local entities = require('entities')
local memory = require('memory')
local player = require('player')
local channel = require('core.channel')
local table = require('table')
local windower = require('core.windower')

local key_fns = {
    t = function() return memory.target_array.targets[memory.target_array.sub_target_mask ~= 0xFFFFFFFF and 1 or 0].entity end,
    st = function() return memory.target_array.sub_target_mask ~= 0xFFFFFFFF and memory.target_array.targets[0].entity end,
    me = function() return memory.entities[player.index] end,
    p0 = function() return memory.entities[memory.party.members[0].index] end,
    p1 = function() return memory.entities[memory.party.members[1].index] end,
    p2 = function() return memory.entities[memory.party.members[2].index] end,
    p3 = function() return memory.entities[memory.party.members[3].index] end,
    p4 = function() return memory.entities[memory.party.members[4].index] end,
    p5 = function() return memory.entities[memory.party.members[5].index] end,
    a10 = function() return memory.entities[memory.party.members[6].index] end,
    a11 = function() return memory.entities[memory.party.members[7].index] end,
    a12 = function() return memory.entities[memory.party.members[8].index] end,
    a13 = function() return memory.entities[memory.party.members[9].index] end,
    a14 = function() return memory.entities[memory.party.members[10].index] end,
    a15 = function() return memory.entities[memory.party.members[11].index] end,
    a20 = function() return memory.entities[memory.party.members[12].index] end,
    a21 = function() return memory.entities[memory.party.members[13].index] end,
    a22 = function() return memory.entities[memory.party.members[14].index] end,
    a23 = function() return memory.entities[memory.party.members[15].index] end,
    a24 = function() return memory.entities[memory.party.members[16].index] end,
    a25 = function() return memory.entities[memory.party.members[17].index] end,
    lastst = function() return memory.entities[memory.target_array.last_st_index] end,
    focusst = function() return memory.entities[memory.target_array.focus_index] end,
    pet = function() return memory.entities[player.pet_index] end,
    -- ft = function() return memory.entities[player.fellow_index] end,
    -- bt = function() return memory.entities[] end,
    -- ht = function() return memory.entities[] end,
    -- scan = function() return memory.entities[] end,
    locked = function() return memory.target_array.target_locked end,
    set = function() return function(id) command.input('/:ta ' .. tostring(id), 'client') end end,
}

local package = windower.package_name

-- Changes to the core channel and event libs are required to make this
-- work in the script environment.
if package then
    local counter = 0
    local pending = {}

    do
        local st_channel = channel.new('__sub_target_channel')
        -- keep channel alive without polluting globals
        pending.channel = st_channel

        st_channel.env = {
            report_result = function(counter, target_id)
                while #pending ~= 0 do
                    local descriptor = table.remove(pending, 1)
                    if descriptor.counter == counter then
                        coroutine.schedule(descriptor.callback, 0, entities:by_id(target_id))
                        return
                    end
                end
            end
        }
    end

    do
        local tobit = bit.tobit
        local valid_sub_targets = {
            ['st'] = true,
            ['stpc'] = true,
            ['stnpc'] = true,
            ['stpt'] = true,
            ['stal'] = true,
        }

        local select = function(target, callback)
            if not valid_sub_targets[target] then
                error('bad argument #1 to \'select\' ' .. 
                    '(expected one of \'st\', \'stpc\', \'stnpc\', \'stpt\' or \'stal\'; ' ..
                    'got \'' .. tostring(target) .. '\')')
            end

            if type(callback) ~= 'function' then
                error('bad argument #2 to \'select\' (function expected; got ' .. type(callback) .. ')')
            end

            local temp = counter
            counter = tobit(counter + 1)
            table.insert(pending, {counter = temp, callback = callback})
            command.input('/:aim \u{FFFD}select_sub_target\u{FFFD} "' .. package .. '" ' .. temp .. ' <' .. target .. '>')
        end

        key_fns.select = function() return select end
    end
end

return setmetatable({}, {
    __index = function(_, key)
        local fn = key_fns[key]
        local res = fn and fn()
        return res ~= nil and res or nil
    end,
    __newindex = function()
        error('Cannot assign to the \'target\' library.')
    end,
    __pairs = function(_)
        return function(t, k)
            local key, fn = next(t, k)
            local res = key and fn()
            return key, res ~= nil and res or nil
        end, key_fns, nil
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
