local types = require('packets:types')
local packet = require('packet')
local ffi = require('ffi')
require('table')
require('string')
require('pack')

local registry = {
    incoming = { all = {} },
    outgoing = { all = {} },
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

local copy_fields
copy_fields = function(packet, raw, instance, fields)
    for _, field in pairs(fields) do
        local type = field.type
        if type.count ~= nil and type.cdef ~= 'char' then
            local res = {}
            local array = instance[field.cname]
            if type.fields ~= nil then
                for i = 0, type.count do
                    local inner = {}
                    copy_fields(inner, nil, array[i], type.fields)
                    res[i] = inner
                end
            else
                for i = 0, type.count do
                    res[i] = array[i]
                end
            end
            packet[field.label] = res
        elseif type.fields ~= nil then
            local res = {}
            copy_fields(res, nil, instance[field.cname], type.fields)
            packet[field.label] = res
        elseif type.cdef ~= nil then
            local data = instance[field.cname]
            packet[field.label] = type.tolua ~= nil and type.tolua(data) or data
        else
            packet[field.label] = raw.data:unpack('z', field.position - 4)
        end
    end
end

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

    local type = types.incoming[raw.id]
    if type ~= nil then
        local instance = type.ctype()
        ffi.copy(instance, char_ptr(dummy_header .. raw.data), type.size)

        copy_fields(packet, raw, instance, type.fields)
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
