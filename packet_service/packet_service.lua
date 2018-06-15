local event = require('event')
local ffi = require('ffi')
local pack = require('pack')
local packet = require('packet')
local shared = require('shared')
local string = require('string')
local table = require('table')
local types = require('types')

packets = shared.new('packets')

local history = {
    raw = {
        incoming = {},
        outgoing = {},
    },
    parsed = {
        incoming = {},
        outgoing = {},
    },
}

local history_raw = history.raw
local history_parsed = history.parsed

local registry = {
    incoming = { all = {} },
    outgoing = { all = {} },
}

local char_ptr = ffi.typeof('char const*')

local copy_fields
copy_fields = function(packet, raw, instance, fields)
    for _, field in pairs(fields) do
        local data
        local type = field.type
        local tolua = type.tolua
        if type.count ~= nil and type.cdef ~= 'char' then
            data = {}
            local array = instance[field.cname]
            if type.base.fields ~= nil then
                for i = 0, type.count do
                    local inner = {}
                    copy_fields(inner, nil, array[i], type.base.fields)
                    data[i] = inner
                end
            else
                if tolua == nil then
                    for i = 0, type.count do
                        data[i] = array[i]
                    end
                else
                    for i = 0, type.count do
                        data[i] = tolua(array[i], field)
                    end
                end
            end
        elseif type.fields ~= nil then
            data = {}
            copy_fields(data, nil, instance[field.cname], type.fields)
        elseif type.cdef ~= nil then
            data = tolua ~= nil and tolua(instance[field.cname], field) or instance[field.cname]
        else
            data = tolua ~= nil and tolua(raw, field) or raw
        end

        packet[field.label] = data
    end
end

local parse = function(packet, types, history_raw, history_parsed)
    local id = packet.id

    local type = types[id]
    if type ~= nil then
        local instance = type.ctype()
        ffi.copy(instance, char_ptr(packet.data), type.size)

        copy_fields(packet, packet.data, instance, type.fields)
    end

    history_parsed[id] = packet
    history_raw[id] = nil

    return packet
end

packets.env = {
    last = function(direction, id)
        local parsed_packet = history_parsed[direction][id]
        if parsed_packet ~= nil then
            return parsed_packet
        end

        local raw_packet = history_raw[direction][id]
        if raw_packet ~= nil then
            return parse(raw_packet, types[direction])
        end

        return nil
    end,
    event = function(direction, id)
        id = id or 'all'

        local reg = registry[direction]
        if reg[id] == nil then
            reg[id] = {}
        end

        local event = event.new()
        reg[id][event] = event
        return event
    end
}

local handle_packet = function(raw, types, registry, history_raw, history_parsed)
    local id = raw.id

    local packet = {
        id = id,
        data = raw.data,
        blocked = raw.blocked,
        modified = raw.modified,
        injected = raw.injected,
    }

    local events_id = registry[id]
    local events_all = registry.all
    if events_id == nil and next(events_all) == nil then
        history_parsed[id] = nil
        history_raw[id] = packet
        return
    end

    packet = parse(packet, types, history_raw, history_parsed)

    for event in pairs(events_id or {}) do
        event:trigger(packet)
    end
    for event in pairs(events_all or {}) do
        event:trigger(packet)
    end
end

local types_incoming = types.incoming
local types_outgoing = types.outgoing
local registry_incoming = registry.incoming
local registry_outgoing = registry.outgoing
local raw_incoming = history_raw.incoming
local raw_outgoing = history_raw.outgoing
local parsed_incoming = history_parsed.incoming
local parsed_outgoing = history_parsed.outgoing

packet.incoming:register(function(raw)
    handle_packet(raw, types_incoming, registry_incoming, raw_incoming, parsed_incoming)
end)

packet.outgoing:register(function(raw)
    handle_packet(raw, types_outgoing, registry_outgoing, raw_outgoing, parsed_outgoing)
end)
