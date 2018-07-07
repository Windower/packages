local windower = require('windower')
local shared = require('shared')

return {
    new = function()
        local name = windower.package_path:gsub('(.+\\)', '')
        local data_server = shared.new(name .. '_data')
        local events_server = shared.new(name .. '_events')

        data_server.data = {}
        data_server.env = {
            select = select,
            next = next,
            type = type,
        }

        events_server.data = {}
        events_server.env = {}

        return data_server, events_server
    end,
}
