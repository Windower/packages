local event = require('event')
local memory = require('memory')
local packets = require('packets')
local shared = require('shared')

account_data = shared.new('account_data')
account_events = shared.new('account_events')

account_data.data = {
    logged_in = false,
}

account_data.env = {
    print = print,
    pairs = pairs,
}

account_events.data = {
    login = event.new(),
    logout = event.new(),
}

local data = account_data.data
local login_event = account_events.data.login
local logout_event = account_events.data.logout

local handle_00A = function(p)
    coroutine.schedule(function()
        local login = not data.logged_in
        if not login then
            return
        end

        local info = memory.account_info
        data.logged_in = true
        data.server = info.server
        data.name = info.name
        data.id = info.id

        login_event:trigger()
    end)
end

local handle_00B = function(p)
    coroutine.schedule(function()
        local logout = p.type == 1
        if not logout then
            return
        end

        data.logged_in = false
        data.server = nil
        data.name = nil
        data.id = nil

        logout_event:trigger()
    end)
end

packets.incoming.register(0x00A, handle_00A)
packets.incoming.register(0x00B, handle_00B)

local last_00A = packets.incoming.last(0x00A)
local last_00B = packets.incoming.last(0x00B)

if last_00A then
    handle_00A(last_00A)
end
if last_00B then
    handle_00B(last_00B)
end
