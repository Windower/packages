local string    = require('string')

local command   = require('command')
local coroutine = require('coroutine')
local tolog     = require('chat').add_text

local inventory = require('items').bags[0]
local player    = require('player')

local handler
do
    local pouches

    local item = {
        count = false,
        delay = false,
        name  = false,
        total = false,
    }

    local prompts = {
        initial = function(item)
            tolog('Pouches Inialized: '.. item.count ..' "'.. item.name ..'" found.', 2)
            tolog('To cancel pouches change player state to anything other than "idle".', 2)
        end,
        no_match = function(item)
            tolog('Pouches Error: Was unable to find item "'.. item.name ..'". '
                ..'Check spelling and/or inventory and try again.', 2)
        end,
        not_idle = function(item)
            tolog('Pouches Canceled: Player state is not "idle".', 2)
        end,
        unusable = function(item)
            tolog('Pouches Error: "'.. item.name .. '" is not a useable item.', 2)
        end,
        complete = function(item)
            tolog('Pouches Complete: '.. item.total ..' '.. item.name ..' used.', 2)
        end,
    }

    pouches = function()
        if player.state.id ~= 0 then
            return prompts.not_idle(item)
        end

        command.input('/item "'.. item.name ..'" <me>')
        item.count = item.count - 1
        item.total = item.total + 1

        if item.count > 0 then
            coroutine.schedule(pouches, item.delay + 2)
        else
            coroutine.schedule(function()
                return prompts.complete(item)
            end, item.delay + 3)
        end
    end

    handler = function(line)
        item = {
            count = 0,
            delay = 0,
            name = line:lower(),
            total = 0,
        }

        for i, k in ipairs(inventory) do
            if k.item then
                if k.item.en:lower() == item.name or k.item.enl:lower() == item.name then
                    item.count = item.count + k.count
                    item.delay = k.item.cast_time or false
                    item.name = k.item.en
                end
            end
        end

        if item.count == 0 then
            return prompts.no_match(item)
        elseif not item.delay then
            return prompts.unusable(item)
        end
        prompts.initial(item)
        pouches()
    end
end

local pouches = command.new('pouches')
pouches:register(handler, '<line:text>')

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
