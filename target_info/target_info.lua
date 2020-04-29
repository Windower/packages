local math = require('math')
local string = require('string')
local ui = require('core.ui')
local target = require('target')

local text_color = ui.color.grey
local config_state = {
    title = 'Target Info',
    style = 'chromeless',
    x = 100,
    y = 0,
    width = 130,
    height = 48,
    color = ui.color.black,
}

local round = function(num)
    return math.floor(num + 0.5)
end

ui.display(function()
    ui.window('target_info', config_state, function()
        local entity = target.st or target.t
        if entity then
            local entity_speed = ((entity.state_id == 5 or entity.state_id == 85) and round(100 * (entity.movement_speed / 4))) or round(100 * (entity.movement_speed / 5 - 1))

            if entity_speed > 0 then
                text_color = ui.color.lightgreen
            elseif entity_speed < 0 then
               text_color = ui.color.red
            else
                text_color = ui.color.grey
            end

            if config_state.color ~= 'ui.color.black' then
                config_state['color'] = ui.color.black
            end

            ui.location(2, 1)
            ui.text('ID:')
            ui.location(45, 1)
            ui.text(tostring(entity.id))
            ui.location(2, 16)
            ui.text('Hex:')
            ui.location(45, 16)
            ui.text(string.format('%03X', entity.index))
            ui.location(2, 31)
            ui.text('Speed:')
            ui.location(45, 31)
            ui.text(tostring(entity_speed..'%'), {color = text_color})
        else
            config_state['color'] = ui.color.transparent
        end
    end)
end)

--[[
Copyright © 2018, Chiaia
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Chiaia nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Chiaia BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
