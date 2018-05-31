require('table')
require('string')
local packet = require('packet')
local fields = require('packets:fields')
local ffi = require('ffi')

require('pack')

local registry = {
    incoming = {},
    outgoing = {},
}

local make_table = function(io)
    local reg = registry[io]
    return {
        register = function(id, fn)
            if type(id) == 'function' then
                fn = id
                id = 'all'
            end

            if reg[id] == nil then
                reg[id] = {}
            end

            reg[id][fn] = fn
            return fn
        end,
        unregister = function(id, fn)
            assert(reg[id], ('No function for ID %i registered.'):format(id))
            assert(reg[id][fn], ('Function not registered for ID %i.'):format(id))

            reg[id][fn] = nil
            reg.all[fn] = nil
        end,
        new = function()
            error('Not yet implemented')
        end,
        last = function()
            error('Not yet implemented')
        end,
    }
end

local char_ptr = ffi.typeof('char const*')

local dummy_header = ('\x00'):rep(4) 

packet.incoming:register(function(raw)
    local fns_id = registry.incoming[raw.id]
    local fns_all = registry.incoming.all
    if fns_id == nil and next(fns_all) == nil then
        return
    end

    local packet = {
        id = raw.id,
        data = raw.data,
        blocked = raw.blocked,
        modified = raw.modified,
        injected = raw.injected,
    }

    local struct = fields.incoming[raw.id]
    if struct ~= nil then
        local instance = ffi.new(struct.cdef)
        ffi.copy(instance, char_ptr(dummy_header .. raw.data), ffi.sizeof(struct.cdef))

        for _, field in pairs(struct.fields) do
            local data = instance[field.cname]
            packet[field.label] = field.type.tolua ~= nil and field.type.tolua(data) or data
        end
    end

    for fn in pairs(fns_id or {}) do
        fn(packet)
    end
    for fn in pairs(fns_all or {}) do
        fn(packet)
    end
end)

-- TODO copy for outgoing...

return {
    incoming = make_table('incoming'),
    outgoing = make_table('outgoing'),
}
