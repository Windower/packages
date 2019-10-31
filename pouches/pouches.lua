local command = require('core.command')
local send_to_chat = require('core.chat').add_text

local data = {}
data.reset = function()
    data.count = 0
    data.delay = false
    data.name = false
end

local cycle_pouches
do
    local player = require('player')
    local coroutine_schedule = require('coroutine').schedule

    cycle_pouches = function()
        command.input('/item \''.. data.name ..'\' <me>')
        data.count = data.count - 1

        if data.count == 0 then
            return coroutine_schedule(function()
                return send_to_chat('Pouches complete...', 55)
            end, data.delay + 3)
        end

        if player.state.id ~= 0 then
            return send_to_chat('Pouches canceled. Player not "Idle".', 55)
        end

        return coroutine_schedule(cycle_pouches, data.delay + 2)
    end
end

local handler
do
    local string = require('string')
    do
        local string_lower = string.lower
        local string_gsub = string.gsub

        string.squash = function(string)
            return string_gsub(string_lower(string), '[%c%p%s]', '')
        end
    end

    handler = function(item, limit)
        data:reset()
        local squash = item:squash()
        for _, k in ipairs(require('items').bags[0]) do
            -- if this table is empty then its 'nil'
            if k.item then
                local key = k.item
                if key.en:squash() == squash or key.enl:squash() == squash then
                    if not key.cast_time then
                        return send_to_chat('Error: "'.. key.en ..'" is not a usable item.')
                    end

                    if not data.delay then
                        data.delay = key.cast_time
                        data.name = key.en
                    end

                    data.count = data.count + k.count
                    if limit and limit <= data.count then
                        data.count = limit
                        break
                    end
                end
            end
        end

        if not data.name then
            return send_to_chat('Error: Could not find "'.. item ..'".')
        end

        send_to_chat('Using '.. data.count ..' of "'.. data.name ..'". Type "/heal" to cancel.', 55)
        return cycle_pouches()
    end
end

local pouches = command.new('pouches')
pouches:register(handler, '<item:string>', '[limit:number]')

--[[
Copyright © 2019; Nekseus, Windower Dev Team
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
