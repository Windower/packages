local event = require('event')
local memory = require('memory')
local packets = require('packets')
local server = require('shared.server')
local res = require('resources')

account_data, account_events = server.new()

account_data.data.logged_in = false

account_events.data.login = event.new()
account_events.data.logout = event.new()

local data = account_data.data
local login_event = account_events.data.login
local logout_event = account_events.data.logout

packets.incoming:register_init({
    [{0x00A}] = function(p)
        local login = not data.logged_in
        if not login then
            return
        end

        coroutine.schedule(function()
            local info = memory.account_info
            data.logged_in = true
            data.server_id = info.server_id % 0x20
            data.name = info.name
            data.id = info.id

            login_event:trigger()
        end)
    end,
    [{0x00B, 0x01}] = function(p)
        local logout = p.type == 1
        if not logout then
            return
        end

        data.logged_in = false
        data.server_id = nil
        data.name = nil
        data.id = nil

        logout_event:trigger()
    end,
})

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
