local party = require('party')
local player = require('player')
local target = require('target')
local packet = require('packet')
local entities = require('entities')
local settings = require('settings')

local ui = require('core.ui')
local command = require('core.command')

local defaults = {
    auto_update = true,

    dress = {
    --[[
        <player_name> = {
            race_model_id = 7 -- id of model to use.
        }
    ]]--
    },
    
    ui = {
        x = 10,
        y = 10,
    },

    blink = {
        follow = {
            always = false,
            target = false
        },
        others = {
            always = false,
            target = false
        },
        party = {
            always = false,
            target = false
        },
        self = {
            always = false,
            target = false
        }
    }
}

local options = settings.load(defaults)

local settings_dialog = {}
local settings_dialog_state = {
    title = 'Dress Up Settings',
    style = 'normal',
    x = options.ui.x,
    y = options.ui.y,
    width = 179,
    height = 96,
    resizable = false,
    moveable = true,
    closable = true,
}

-- Command Arg Types
-- Create and Register types
local arg_lookups = {
    conditions = {
        ['target'] = true,
        ['always'] = true,
        ['combat'] = true,
        ['all'] = true,
    },
    groups = {
        ['others'] = 'others',
        ['o'] = 'others',
        ['follow'] = 'follow',
        ['f'] = 'follow',
        ['party'] = 'party',
        ['p'] = 'party',
        ['self'] = 'self',
        ['s'] = 'self',
        ['all'] = 'all',
        ['a'] = 'all',
    },

    bool = {
        ['1'] = true,
        ['true'] = true,
        ['t'] = true,
        ['yes'] = true,
        ['y'] = true,
        ['on'] = true,
        ['0'] = false,
        ['false'] = false,
        ['f'] = false,
        ['no'] = false,
        ['n'] = false,
        ['off'] = false,
    },
}

command.arg.register('name', '<name:string(%a+)>')
command.arg.register('condition', '<condition:one_of(all,always,target)>')
command.arg.register('model_name', '<model_name:one_of(face,race,head,body,hands,legs,feet,main,sub,ranged)>')


command.arg.register_type('lookup_boolean', {
    check = function(str)
        local bool = arg_lookups.bool[str]
        if bool ~= nil then
            return bool
        end

        error('Expected one of \'' .. table.concat(arg_lookups.bool, ',') .. '\', received \'' .. str .. '\'.')
    end
})
command.arg.register_type('lookup_group', {
    check = function(str)
        local group = arg_lookups.groups[str]
        if group ~= nil then
            return group
        end

        error('Expected one of \'' .. table.concat(arg_lookups.groups, ',') .. '\', received \'' .. str .. '\'.')
    end
})

-- Addon Command Handlers
local du = command.new('du')

local clear = function(target, model)
    local t = options.dress[target]
    if t then
        t[model .. '_model_id'] = nil
    end
    settings.save()
end

du:register('c', clear, '{name} {model_name}')
du:register('clear', clear, '{name} {model_name}')


local replace = function(target, change)
    --TODO: add 1:1 replace functionality.
end

du:register('r', replace, '{name}')
du:register('replace', replace, '{name}')


local dress = function(target, model, change)
    local t = options.dress[target] or {}
    t[model .. '_model_id'] = change
    options.dress[target] = t
    settings.save()
end

du:register('d', dress, '{name} {model_name} <id:integer>')
du:register('dress', dress, '{name} {model_name} <id:integer>')


local blink = function(group, condition, bool)
    if condition == 'all' then
        for k in pairs(options.blink[group]) do
          options.blink[group][k] = bool
        end
    else
        options.blink[group][condition] = bool
    end
    settings.save()
end

du:register('b', blink, '<group:lookup_group> {condition} <enabled:lookup_boolean>')
du:register('blink', blink, '<group:lookup_group> {condition} <enabled:lookup_boolean>')


local auto_update_enable = function(bool)
    options.auto_update = bool
    settings.save()
end

du:register('auto_update', auto_update_enable, '<enabled:lookup_boolean>')


-- Packet Event Handlers
-- Model change Events

-- Model changes for other players
packet.incoming[0x00D]:register(function(p, info)

    if p.update_model then
        local entity = entities[p.player_index]
        if entity then
            local group = 'others'
            local is_party_member = false
            for i = 1, 18, 1 do
                if party[i] then
                    is_party_member = party[i].index == p.player_index
                end
            end

            if is_party_member then
                group = 'party'
            end

            local is_target = (target.t and p.player_index == target.t.index) or (target.st and p.player_index == target.st.index) or false

            local bmn = options.blink[group]

            if bmn.always or (bmn.target and is_target) then
                p.update_model = false
            elseif options.dress[entity.name] then
                p.race_id = options.dress[entity.name].race_model_id or p.race_id
                p.face_model_id = options.dress[entity.name].face_model_id or p.face_model_id

                for k, v in pairs(p.model) do
                    p.model[k] = options.dress[entity.name][k] or v
                end
            end
        end
    end
end)
-- Model changes for self
packet.incoming[0x051]:register(function(p, info)
    local have_target = (target.t or target.st) ~= nil or false

    local bmn = options.blink['self']

    if bmn.always or (bmn.target and have_target) then
        p.update_model = false
    elseif options.dress[player.name] then
        p.race_id = options.dress[player.name].race_model_id or p.race_id
        p.face_model_id = options.dress[player.name].face_model_id or p.face_model_id

        for k, v in pairs(p.model) do
            p.model[k] = options.dress[player.name][k] or v
        end
    end
end)

-- User Interface
-- Setting menus
ui.display(function()
-- TODO: create user interface for making changes to player models.
end)

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
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS' AND
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
