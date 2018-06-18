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
