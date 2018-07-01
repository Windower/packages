local event = require('event')
local shared = require('shared')

local fetch_data = shared.get('account_service', 'account_data')
local fetch_events = shared.get('account_service', 'account_events')

local account = {}

account.login = event.slim.new()
account.logout = event.slim.new()

fetch_events:read('login'):register(function()
    account.login:trigger()
end)

fetch_events:read('logout'):register(function()
    account.logout:trigger()
end)

local server_names = {
    [2] = 'Undine',
    [4] = 'Bahamut',
    [5] = 'Shiva',
    [8] = 'Phoenix',
    [9] = 'Carbuncle',
    [10] = 'Fenrir',
    [11] = 'Sylph',
    [12] = 'Valefor',
    [14] = 'Leviathan',
    [15] = 'Odin',
    [19] = 'Quetzalcoatl',
    [20] = 'Siren',
    [23] = 'Ragnarok',
    [26] = 'Cerberus',
    [28] = 'Bismarck',
    [30] = 'Lakshmi',
    [31] = 'Asura',
}

return setmetatable(account, {
    __index = function(_, name)
        if name == 'server_name' then
            return server_names[fetch_data:read('server')]
        end

        return fetch_data:read(name)
    end,
    __pairs = error, -- TODO
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
