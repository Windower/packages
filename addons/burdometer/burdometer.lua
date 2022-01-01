local string = require('string')

local ui = require('core.ui')
local command = require('core.command')
local windower = require('core.windower')

local player = require('player')
local settings = require('settings')

local burden = require('burden')

local defaults = {
    ui = {
        x = 145,
        y = 200,
    },
    window_style = 'standard',
}

local options = settings.load(defaults)

local burden_window_state = ui.window_state()
burden_window_state.title = 'Burden'
burden_window_state.style = options.window_style
burden_window_state.position = {x = options.ui.x, y = options.ui.y}
burden_window_state.size = {width = 120, height = 200}
burden_window_state.resizable = false
burden_window_state.movable = true

local progress_entries = ui.progress_entries(3)

do
    local handle_options_change = function(options)
        burden_window_state.position = {options.ui.x, y = options.ui.y}
        burden_window_state.style = options.window_style
        burden_window_state.color = options.window_style == 'chromeless' and ui.color.transparent or nil
    end

    settings.settings_change:register(handle_options_change)
end

local cmd = command.new('burden')

local function move_window(x,y)
    burden_window_state.position = {x = x, y = y}
end
cmd:register('pos', move_window, '<x:number> <y:number>')

local function set_window_style(style)
    options.window_style = style

    burden_window_state.style = style

    settings.save()
end
cmd:register('style', set_window_style, '<window_style:one_of(chromeless,standard,layout)>')


local function draw_burden(element, value, y, meter)
    local risk = value - burden.threshold

    progress_entries[1].value = value
    progress_entries[2].max = burden.threshold
    progress_entries[1].color = risk < 0 and ui.color.limegreen or ui.color.rgb(255,204,0)

    progress_entries[2].value = risk
    progress_entries[2].max = 100
    progress_entries[2].color = ui.color.red

    meter:padding(0,0,0,0):move(18, y + 7):size(100, 10):progress(progress_entries)

    meter:padding(0,0,0,0):move(18, y):label(tostring(value))

    meter:padding(0,0,0,0):move(92, y):label(tostring(risk > 0 and risk or 0))

    ui.primitive.rectangle(0, y + 2, 16, 16, windower.package_path .. '\\icons\\' .. element .. '.png');
end

local ele_order = {
    'fire',
    'earth',
    'water',
    'wind',
    'ice',
    'thunder',
    'light',
    'dark',
}

ui.display(function()
    if not (player.main_job_id == 0x12 or player.sub_job_id == 0x12 or burden_window_state.style == 'layout') then
        return
    end

    local height = 0
    for _, v in ipairs(burden) do
        if v ~= 0 then
            height = height + 20
        end
    end

    if burden_window_state.style == 'layout' then
        height = 200
    end

    ui.window(burden_window_state, function(meter)
        local y = 0
        for _, ele in ipairs(ele_order) do
            if burden[ele] ~= 0 then
                draw_burden(ele, burden[ele], y, meter)
                y = y + 20
            end
        end
        burden_window_state.size = {width = burden_window_state.size.width, height = y}
    end)

    if burden_window_state.position.x ~= options.ui.x or burden_window_state.position.y ~= options.ui.y then
        options.ui.x = burden_window_state.position.x
        options.ui.y = burden_window_state.position.y
        settings.save()
    end
end)

--[[
Copyright © 2020,2021 Windower Dev Team
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
