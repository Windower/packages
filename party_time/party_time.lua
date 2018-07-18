local os = require('os')
local ui = require('ui')
local sets = require('sets')
local string = require('string')
local command = require('command')
local packets = require('packets')
local settings = require('settings')
local treasure = require('treasure')

local defaults = {
    ui = {
        x = 145,
        y = 440,
        enabled = true,
    },
    auto = {
        accept = true,   -- also for auto sending invites upon party requests
        decline = false, -- also ignores party requests from players on blacklists
    },
    default = 'ask'      -- sets defualt behavior for unhandled invites. ask user, treat as whitelist, treat as blacklist,
    blacklist = sets({}),
    whitelist = sets({}),
}
settings.settings_change:register(function(options)
    options.blacklist = sets(options.blacklist)
    options.whitelist = sets(options.whitelist)
end)
options = settings.load(defaults)

local invite_dialog = {}
local invite_dialog_state = {
    title = 'Party Invite',
    style = 'normal',
    x = options.ui.x,
    y = options.ui.y,
    width = 179,
    height = 96,
    resizable = false,
    moveable = true,
    closable = true,
}
local unhandled_requests = {}
local unhandled_invite = false

-- Command Arg Types
-- Create and Register types
local arg_lookups = {
    addremove = {
        ['add'] = 'union',
        ['a'] = 'union',
        ['+'] = 'union',
        ['remove'] = 'difference',
        ['rm'] = 'difference',
        ['r'] = 'difference',
        ['-'] = 'difference',
    },
    option = {
        ['ask'] = 'ask',
        ['a'] = 'ask',
        ['whitelist'] = 'whitelist',
        ['w'] = 'whitelist',
        ['blacklist'] = 'blacklist',
        ['b'] = 'blacklist',
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

command.arg.register_type('lookup_boolean', {
    check = function(str)
        local bool = arg_lookups.bool[str]
        if bool ~= nil then
            return bool
        end

        error('Expected one of \'' .. table.concat(args_lookups.bool, ',') .. '\', received \'' .. str .. '\'.')
    end
})

command.arg.register_type('lookup_add_remove', {
    check = function(str)
        local op = arg_lookups.addremove[str]
        if op ~= nil then
            return op
        end

        error('Expected one of \'' .. table.concat(args_lookups.addremove, ',') .. '\', received \'' .. str .. '\'.')
    end
})
command.arg.register_type('lookup_option', {
    check = function(str)
        local option = arg_lookups.option[str]
        if option ~= nil then
            return option
        end

        error('Expected one of \'' .. table.concat(args_lookups.option, ',') .. '\', received \'' .. str .. '\'.')
    end
})

-- Addon Command Handlers
-- Seven main commands additoinal sub_commands within
local pt = command.new('pt')

local invite = function(...)
    for _, name in pairs({...}) do
        command.input('/pcmd add ' .. name)
        name = name:gsub('^%l', string.upper)
        if unhandled_requests[name] then
            unhandled_requests[name] = nil
        end
    end
end

pt:register('i', invite, '{name}*')
pt:register('invite', invite, '{name}*')


local request = function(name)
    command.input('/prcmd add ' .. name)
end

pt:register('r', request, '{name}')
pt:register('request', request, '{name}')


local blacklist = function(sub_cmd, ...)
    local names = sets({...})
    options.blacklist[sub_cmd](options.blacklist, names)
    settings.save(options)
end

pt:register('b', blacklist, '<sub_cmd:lookup_add_remove> {name}*')
pt:register('blacklist', blacklist, '<sub_cmd:lookup_add_remove> {name}*')


local whitelist = function(sub_cmd, ...)
    local names = sets({...})
    options.whitelist[sub_cmd](options.whitelist, names)
    settings.save(options)
end

pt:register('w', whitelist, '<sub_cmd:lookup_add_remove> {name}*')
pt:register('whitelist', whitelist, '<sub_cmd:lookup_add_remove> {name}*')


local ui_enable = function(bool)
    options.ui.enabled = bool
    settings.save(options)
end

pt:register('ui_enable', ui_enable, '<enabled:lookup_boolean>')


local auto_accept_enable = function(bool)
    options.auto.accept = bool
    settings.save(options)
end

pt:register('auto_accept', auto_accept_enable, '<enabled:lookup_boolean>')


local auto_decline_enable = function(bool)
    options.auto.decline = bool
    settings.save(options)
end

pt:register('auto_decline', auto_decline_enable, '<enabled:lookup_boolean>')


local default_handler = function(option)
    options.default = option
    settings.save(options)
end

pt:register('defualt', default_handler, '<option:lookup_option>')

-- Packet Event Handlers
-- Recieve Invites & Recieve Requests
local default_handlers = {
    invite = {
        ask = function(name)
            invite_dialog = {
                state = invite_dialog_state,
                add_to_whitelist = false,
                name = name,
            }
            unhandled_invite = true,
        end,
        whitelist = function()
            coroutine.schedule(function()
                local clock = os.clock()
                repeat
                    if (os.clock() - clock) > 90 then
                        return
                    end
                    coroutine.sleep_frame()
                until(#treasure == 0)
                command.input('/join')
            end)
        end,
        blacklist = function()
            command.input('/decline')
        end
    },
    request = { 
        ask = function(name)
            unhandled_requests[name] = {
                state = {
                    title = 'Party Request',
                    style = 'normal',
                    x = options.ui.x,
                    y = options.ui.y,
                    width = 179,
                    height = 96,
                    resizable = false,
                    moveable = true,
                    closable = true,
                },
                add_to_whitelist = false,
            }
        end,
        whitelist = function(name)
            command.input('/pcmd add '.. name)
        end,
        blacklist = function()
            return
        end,
    }
}

packets.incoming[0x0DC]:register(function(p)
    if options.auto.accept and options.whitelist:contains(p.player_name) then
        coroutine.schedule(function()
            local clock = os.clock()
            repeat
                if (os.clock() - clock) > 90 then
                    return
                end
                coroutine.sleep_frame()
            until(#treasure == 0)
            command.input('/join')
        end)
    elseif options.auto.decline and options.blacklist:contains(p.player_name) then
        command.input('/decline')
    else
        default.invite[options.default](p.player_name)
    end
end)

packets.incoming[0x11D]:register(function(p)
    if options.auto.accept and options.whitelist:contains(p.player_name) then
        command.input('/pcmd add '..p.player_name)
    elseif options.auto.decline and options.blacklist:contains(p.player_name) then
        return --ignore request by providing a dialog to user
    else
        default.request[options.default](p.player_name)
    end
end)

packets.outgoing[0x074]:register(function(p)
    unhandled_invite = false
end)

-- User Interface for Accepting|Declining
-- Pop-Up menus Invites & Requests
ui.display(function()
    if options.ui.enabled then
        if unhandled_invite then
            invite_dialog.state, invite_dialog.closed = ui.window('invite_dialog', invite_dialog.state, function()

                ui.location(11, 5)
                ui.text(invite_dialog.name .. ' has invited\nyou to join their party')
                
                ui.location(11, 50)
                if options.auto.accept then
                    if ui.check('add_to_whitelist', 'Remember ' .. invite_dialog.name, invite_dialog.add_to_whitelist) then
                        invite_dialog.add_to_whitelist = not invite_dialog.add_to_whitelist
                    end
                else
                    if ui.check('add_to_whitelist', 'Turn auto accept on', options.auto.accept) then
                        options.auto.accept = true
                    end
                end

                ui.location(11,72)
                if ui.button('accept', 'Accept') then
                    command.input('/join')
                    unhandled_invite = false
                    if invite_dialog.add_to_whitelist then
                        options.whitelist:add(invite_dialog.name)
                        settings.save(options)
                    end
                end
                ui.location(93,72)
                if ui.button('decline', 'Decline') then
                    command.input('/decline')
                    unhandled_invite = false
                end

            end)
            if invite_dialog.closed then
                invite_dialog.closed = nil
                unhandled_invite = false
            end
            if invite_dialog.state.x ~= options.ui.x or invite_dialog.state.y ~= options.ui.y then
                options.ui.x = invite_dialog.state.x
                options.ui.y = invite_dialog.state.y
                invite_dialog_state.x = invite_dialog.state.x
                invite_dialog_state.y = invite_dialog.state.y
                settings.save(options)
            end
        end

        local closed_dialogs = {}
        for id, request_dialog in pairs(unhandled_requests) do 
            request_dialog.state, request_dialog.close = ui.window(id, request_dialog.state, function()
                ui.location(11, 5)
                ui.text(id .. ' has requested\nto join your party')
                
                ui.location(11, 50)
                if options.auto.accept then
                    if ui.check('add_to_whitelist', 'Remember ' .. id, request_dialog.add_to_whitelist) then
                        request_dialog.add_to_whitelist = not request_dialog.add_to_whitelist
                    end
                else
                    if ui.check('add_to_whitelist', 'Turn auto accept on ', options.auto.accept) then
                        options.auto.accept = true
                    end
                end

                ui.location(11,72)
                if ui.button('invite', 'Invite') then
                    command.input('/pcmd add ' .. id)
                    closed_dialogs[#closed_dialogs + 1] = id
                    if request_dialog.add_to_whitelist then
                        options.whitelist:add(id)
                        settings.save(options)
                    end
                end
                ui.location(93,72)
                if ui.button('ignore', 'Ignore') then
                    closed_dialogs[#closed_dialogs + 1] = id
                end
            end)
            if request_dialog.close then
                closed_dialogs[#closed_dialogs + 1] = id
            end
            if request_dialog.state.x ~= options.ui.x or request_dialog.state.y ~= options.ui.y then
                options.ui.x = request_dialog.state.x
                options.ui.y = request_dialog.state.y
                invite_dialog_state.x = request_dialog.state.x
                invite_dialog_state.y = request_dialog.state.y
                settings.save(options)
            end
        end

        for _, id in pairs(closed_dialogs) do
            unhandled_requests[id] = nil
        end
    end
end)

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
