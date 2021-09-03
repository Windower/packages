local settings = require('settings')
local automaton = require('automaton')

local command = require('core.command')

local defaults = {
    equip_delay = 0.5,
    sets = {}
}
local options = settings.load(defaults)

command.arg.register('set_name', '<set_name:string>')

-- Addon command Handlers
local ps = command.new('ps')

local equip_set = function(set_name)
    local set = options.sets[set_name]
    if not automaton.activated then
        coroutine.schedule(function()
            automaton:remove_all()

            --TODO: inform user start of set equipping
            coroutine.sleep(options.equip_delay)
            automaton:equip_head(set.head)

            coroutine.sleep(options.equip_delay)
            automaton:equip_frame(set.frame)

            local equip_attachment = automaton.equip_attachment
            for slot, attachment in pairs(set.attachments) do
                coroutine.sleep(options.equip_delay)
                equip_attachment(automaton, slot, attachment)
            end
            --TODO: inform user set equip is complete
        end)
    else
        --TODO: inform user equip failed, automaton is currently active
    end
end
ps:register('e', equip_set, '{set_name}')
ps:register('equipset', equip_set, '{set_name}')

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

        attachments = {}
    }

    for _, attachment in pairs(automaton.attachments) do
        set.attachments[attachment.slot] = attachment.item and attachment.item.name
    end

    options.sets[set_name] = set
    settings.save()
end
ps:register('s', save_set, '{set_name}')
ps:register('save', save_set, '{set_name}')

local list_sets = function()
    for set in pairs(options.sets) do
        --TODO: show user list of sets.
    end
end
ps:register('l', list_sets)
ps:register('list', list_sets)

local set_delay = function(delay)
    options.equip_delay = delay
    settings.save()
end
ps:register('d', set_delay, '<delay:number>')
ps:register('delay', set_delay, '<delay:number>')

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
            print(attachment)
            invalid[#invalid + 1] = attachment
        end
    end
    return invalid
end

settings.settings_change:register(function()
    for name, set in pairs(options.sets) do
        local invalid = validate_set(set)

        if #invalid > 0 then
            local invalid_string = ""

            for _, v in ipairs(invalid) do
                invalid_string = invalid_string .. v .. " "
            end

            error("Invalid set_name: " .. name .. ", set: " .. invalid_string)
        end
    end
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
