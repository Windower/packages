local settings = require('settings')
local automaton = require('automaton')

local ui = require('core.ui')
local command = require('core.command')
local windower = require('core.windower')

local os = require('os')
local string = require('string')

local defaults = {
    equip_delay = 0.5,
    sets = {},
}
local options = settings.load(defaults)

local window = {}
window.state = {
    style = 'chromeless',
    title = 'pupswap',
    x = windower.settings.ui_size.width - 240,
    y = windower.settings.ui_size.height - 20,
    width = 100,
    height = 19,
    color = ui.color.rgb(0,0,0,40),
    resizable = false,
    moveable = true,
    closable = true,
}

local state = ''
local icons_path = windower.package_path .. '\\icons\\'

command.arg.register('set_name', '<set_name:string>')

-- Addon command Handlers
local ps = command.new('ps')

local equip_set = function(set_name)
    local set = options.sets[set_name]
    if not automaton.activated and set ~= nil then
        coroutine.schedule(function()
            automaton:remove_all()

            state = 'Equipping...'

            coroutine.sleep(options.equip_delay)
            automaton:equip_head(set.head)

            coroutine.sleep(options.equip_delay)
            automaton:equip_frame(set.frame)

            local equip_attachment = automaton.equip_attachment
            for slot, attachment in pairs(set.attachments) do
                coroutine.sleep(options.equip_delay)
                equip_attachment(automaton, slot, attachment)
            end
            state = set_name

        end)
    else
        --TODO: inform user equip failed, automaton is currently active
    end
end
ps:register('(e)quipset', equip_set, '{set_name}')

local deactivate_equip_activate = function (set_name)
    coroutine.schedule(function ()
        automaton:deactivate()
        coroutine.sleep(1.5)
        equip_set(set_name)
        coroutine.sleep(options.equip_delay * 14)
        automaton:active()
    end)
end
ps:register('dea', deactivate_equip_activate, '{set_name}')

local save_set = function(set_name)
    local set = {
        head = automaton.head.name,
        frame = automaton.frame.name,

        attachments = {},
    }

    for _, attachment in pairs(automaton.attachments) do
        set.attachments[attachment.slot] = attachment.item and attachment.item.name
    end

    options.sets[set_name] = set
    settings.save()
end
ps:register('(s)ave', save_set, '{set_name}')

local list_sets = function()
    for set in pairs(options.sets) do
        --TODO: show user list of sets.
    end
end
ps:register('(l)ist', list_sets)

local set_delay = function(delay)
    options.equip_delay = delay
    settings.save()
end
ps:register('(d)elay', set_delay, '<delay:number>')

local validate_set = function(set)
    local invalid =  {}
    if not automaton.validate_head_name(set.head) then
        invalid[#invalid + 1] = set.head
    end

    if not automaton.validate_frame_name(set.frame) then
        invalid[#invalid + 1] = set.frame
    end

    for _, attachment in pairs(set.attachments) do
        if not automaton.validate_attachment_name(attachment) then
            invalid[#invalid + 1] = attachment
        end
    end
    return invalid
end

local validate_settings = function()
    for name, set in pairs(options.sets) do
        local invalid = validate_set(set)

        if #invalid > 0 then
            local invalid_string = ''

            for _, v in ipairs(invalid) do
                invalid_string = invalid_string .. v .. ' '
            end

            error('Invalid set_name: ' .. name .. ', invalid: ' .. invalid_string)
        end
    end
end
validate_settings()

settings.settings_change:register(function()
    validate_settings()
end)


local animate_image = function(image_prefix, image_extenstion, count, duration) --TODO: replace with ui animation solution when avaliable.
    local images = {}
    for i = 1, count do
        images[i] = image_prefix .. i .. image_extenstion
    end

    local image_color = {}
    local current_frame = 1
    local last_time = os.clock()
    return function()

        if os.clock() - last_time > duration then
            current_frame = (current_frame % count) + 1
            last_time = os.clock()
        end
        ui.image(images[current_frame], image_color)
    end
end

local animated_image = animate_image(icons_path .. 'loading_', '.png', 8, 0.2)
ui.display(function()
    local image_color = {}
    window.state, window.closed = ui.window('window', window.state, function()
        ui.location(21, 0, 0)
        ui.text(string.format('[%s]{stroke:"1px"}', state))

        ui.location(0, 0)
        ui.size(19, 20)
        if state == 'Equipping...' then
            animated_image()
        else
            ui.image(icons_path .. 'idle.png', image_color)
        end
    end)
end)

--[[
Copyright © 2021, Windower Dev Team
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
