local chat = require('core.chat')
local command = require('core.command')
local coroutine = require('coroutine')
local items = require('items')
local player = require('player')
local string = require('string.ext')

local add_text = chat.add_text

local cycle_pouches
do
    local coroutine_schedule = coroutine.schedule

    cycle_pouches = function(item, count, delay)
        if player.state.id ~= 0 then
            return
        end

        command.input('/item "'.. item ..'" <me>')
        count = count - 1

        if count == 0 or player.state.id ~= 0 then
            return
        end

        coroutine_schedule(function()
            cycle_pouches(item, count, delay)
        end, delay)
    end
end

local handler
do
    local inventory = items.bags[0]

    handler = function(item, limit)
        local item_normalized = item:normalize()
        local count = 0
        local delay

        for _, k in ipairs(inventory) do
            if k.item then
                local key = k.item
                if key.name:normalize() == item_normalized or key.enl:normalize() == item_normalized then
                    if key.category ~= 'Usable' then
                        add_text('Error: "'.. item ..'" is not a usable item.', 55)
                        return
                    end

                    count = count + k.count
                    delay = key.cast_time
                    item = key.name

                    if limit and limit <= count then
                        count = limit
                        break
                    end
                end
            end
        end

        if count == 0 then
            add_text('Error: Could not find "'.. item ..'".', 55)
            return
        end

        add_text('Using '.. count ..' of "'.. item ..'". Type "/heal" to cancel.', 55)
        cycle_pouches(item, count, delay + 2)
    end
end

local pouches = command.new('pouches')
pouches:register(handler, '<item:string>', '[limit:number]')

--[[
Copyright © 2019, Nekseus
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Nekseus nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL NEKSEUS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
