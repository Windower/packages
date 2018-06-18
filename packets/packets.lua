local event = require('event')
local shared = require('shared')

local fetch = shared.get('packet_service', 'packets')

local get_last = function(_, direction, id)
    return get_last(direction, id)
end

local make_event = function(_, direction, id)
    return make_event(direction, id)
end

local registry = {
    incoming = {},
    outgoing = {},
}

local make_table = function(direction)
    local reg = registry[direction]
    return {
        register = function(id, fn)
            if type(id) == 'function' then
                fn = id
                id = 'all'
            end

            if reg[id] == nil then
                reg[id] = fetch:call(make_event, direction, id)
            end

            local event = reg[id]
            event:register(fn)
        end,
        unregister = function(id, fn)
            if type(id) == 'function' then
                fn = id
                id = 'all'
            end

            reg[id]:unregister(fn)
        end,
        new = function()
            error('Not yet implemented')
        end,
        last = function(id)
            return fetch:call(get_last, direction, id)
        end,
    }
end

return {
    incoming = make_table('incoming'),
    outgoing = make_table('outgoing'),
}
