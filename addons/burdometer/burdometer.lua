local burden = require('burden')
local string = require('string')
local settings = require('settings')

local ui = require('core.ui')
local command = require('core.command')
local windower = require('core.windower')


local defaults = {
    ui = {
        x = 145,
        y = 200,
    },
    window_style = 'normal',
}

local options = settings.load(defaults)

local burden_window = {
    state = {
        title = 'Burden',
        style = options.window_style,
        x = options.ui.x,
        y = options.ui.y,
        width = 118,
        height = 144,
        color = options.window_style == 'chromeless' and ui.color.transparent or nil,
        resizable = false,
        moveable = true,
    }
}

local cmd = command.new('burden')

local function move_window(x,y)
    burden_window.state.x = x
    burden_window.state.y = y
end
cmd:register('pos', move_window, '<x:number> <y:number>')

local function set_window_style(style)
    options.window_style = style

    burden_window.state.style = style
    burden_window.state.color = options.window_style == 'chromeless' and ui.color.transparent or nil

    settings.save()
end
cmd:register('style', set_window_style, '<window_style:one_of(chromeless,normal,layout)>')


local function draw_burden(element, value, y)
    local image_color = {}

    ui.location(18, 7 + y)
    ui.size(100, 10)

    local remaining_time = (value / burden.decay_rate) * 3
    local progress = (value/burden.threshold)
    local risk = value - burden.threshold

    local color
    if risk > 32 then
        color = ui.color.red
    elseif risk > 24 then
        color = ui.color.orange
    elseif risk > 0 then
        color = ui.color.rgb(255,204,0)
    else
        color = ui.color.limegreen
    end

    ui.progress(progress, {color = color})

    ui.location(18, -2 + y)
    ui.text(string.format('[%s]{stroke:"1px"}', value))

    ui.location(92, -2 + y)
    ui.text(string.format('[%s%%]{stroke:"1px"}', risk > 0 and risk or 0))

    ui.location(0, 0 + y)
    ui.size(16, 16)
    ui.image(windower.package_path .. '\\icons\\' .. element .. '.png', image_color)
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
    local height = 0
    for _, v in pairs(burden) do
        if v ~= 0 then
            height = height + 18
        end
    end
    burden_window.state.height = height

    burden_window.state, burden_window.closed = ui.window('burden_window', burden_window.state, function()
        local y = 0
        for _, ele in pairs(ele_order) do
            if burden[ele] ~= 0 then
                draw_burden(ele, burden[ele], y)
                y = y + 18
            end
        end
        burden_window.state.height = y
    end)

    if burden_window.state.x ~= options.ui.x or burden_window.state.y ~= options.ui.y then
        options.ui.x = burden_window.state.x
        options.ui.y = burden_window.state.y
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
