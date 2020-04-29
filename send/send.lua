local command = require('core.command')
local entities = require('entities')
local ipc = require('ipc')
local player = require('player')
local target = require('target')

local send_message = function(message)
    local receiver, cmd = command.core.parse_args(message:sub(7), 1)

    receiver = receiver:lower()
    cmd = cmd:gsub('%b{}', function(match)
        match = match:sub(2, -2)

        local target_string = match:match('%w+')
        local target_index = tonumber(target_string)
        local entity = target_index and entities[target_index] or target[target_string]
        assert(entity, 'Cannot resolve <' .. target_string .. '>.')

        local accessor = match:sub(#target_string + 1)
        local ok, result = pcall(loadstring('local entity = ... return entity' .. accessor), entity)
        assert(ok and result ~= nil, 'Cannot resolve path \'<' .. target_string .. '>' .. accessor .. '\'.')

        return tostring(result)
    end)

    ipc.send(receiver .. ' ' .. cmd)
end

ipc.received:register(function(message)
    local receiver, cmd = command.core.parse_args(message, 1)
    if receiver == player.name:lower() or receiver == '@all' then
        command.input(cmd, 'client')
    end
end)

command.core.register('send', function(_, message)
    message = message:gsub('{(%w+)}', '{%1.id}')

    local st
    for match in message:gmatch('%b{}') do
        if match:sub(2, 3) == 'st' then
            assert(not st, 'Send does not support multiple <st> selections.')
            st = {}
            st.identifier, st.accessor = match:match('^{(%w+)(.*)}$')
            st.from, st.to = message:find(match, 1, true)
        end
    end

    if st then
        target.select(st.identifier, function(entity)
            send_message(message:sub(1, st.from) .. entity.index .. st.accessor .. message:sub(st.to))
        end)
    else
        send_message(message)
    end
end, true)

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
