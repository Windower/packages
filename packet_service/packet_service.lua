local event = require('event')
local ffi = require('ffi')
local packet = require('packet')
local shared = require('shared')
local string = require('string')
local table = require('table')
local types = require('types')
local os = require('os')

packets = shared.new('packets')

local nesting_meta
nesting_meta = {
    __index = function(t, k)
        local v = setmetatable({}, nesting_meta)
        t[k] = v
        return v
    end,
}

local registry = setmetatable({}, nesting_meta)
local history = setmetatable({}, nesting_meta)

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
                for i = 0, type.count - 1 do
                    data[i] = copy_fields({}, nil, array[i], type.base.fields)
                end
            else
                if tolua == nil then
                    for i = 0, type.count - 1 do
                        data[i] = array[i]
                    end
                else
                    for i = 0, type.count - 1 do
                        data[i] = tolua(array[i], field)
                    end
                end
            end
        elseif type.fields ~= nil then
            data = copy_fields({}, nil, instance[field.cname], type.fields)
        elseif type.cdef ~= nil then
            data = tolua ~= nil and tolua(instance[field.cname], field) or instance[field.cname]
        else
            data = tolua ~= nil and tolua(raw, field) or raw
        end

        packet[field.label] = data
    end

    return packet
end

local parse_single
parse_single = function(packet, ptr, type)
    if type == nil then
        return
    end

    if type.multiple == nil then
        local instance = type.ctype()
        ffi.copy(instance, ptr, type.size)

        copy_fields(packet, packet.data, instance, type.fields)
        return
    end

    local indices = {parse_single(packet, ptr, type.base)}
    ptr = ptr + type.base.size

    do
        local lookups = type.lookups
        local base_index = #indices
        for i = 1, #lookups do
            indices[base_index + i] = packet[lookups[i]]
        end
    end

    local new_type = type
    for i = 1, #indices do
        local index = indices[i]
        new_type = new_type[index]

        if new_type == nil then
            return unpack(indices)
        end
    end

    do
        local new_indices = {parse_single(packet, ptr, new_type)}
        local base_index = #indices
        for i = 1, #new_indices do
            indices[base_index + i] = new_indices[i]
        end
    end

    return unpack(indices)
end

packets.env = {
    get_last = function(...)
        local history = history
        for i = 1, select('#', ...) do
            history = rawget(history, select(i, ...))
            if not history then
                return nil
            end
        end

        return history
    end,
    make_event = function(...)
        local registry = registry
        for i = 1, select('#', ...) do
            registry = registry[select(i, ...)]
        end

        local event = event.new()
        local events = registry.events
        events[#events + 1] = event

        return event
    end,
}

local trigger_events = function(events, packet)
    if not events then
        return
    end

    for i = 1, #events do
        events[i]:trigger(packet)
    end
end

local make_timestamp
do
    local last_time = os.time()
    local now_count = 0

    make_timestamp = function()
        local now = os.time()
        if last_time == now then
            now_count = now_count + 1
            return now + now_count / 10000
        end

        now_count = 0
        last_time = now
        return now
    end
end

local handle_packet = function(direction, raw)
    local id = raw.id

    local packet = {
        id = id,
        direction = direction,
        data = raw.data,
        blocked = raw.blocked,
        modified = raw.modified,
        injected = raw.injected,
        timestamp = make_timestamp(),
    }

    local indices = {direction, id, parse_single(packet, char_ptr(packet.data), types[direction][id])}

    local registry = registry
    local history = history
    trigger_events(registry.events, packet)
    local indices_count = #indices
    for i = 1, indices_count do
        local index = indices[i]
        registry = registry[index]
        trigger_events(registry.events, packet)

        if i ~= indices_count then
            history = history[index]
        else
            history[index] = packet
        end
    end
end

packet.incoming:register(function(raw)
    handle_packet('incoming', raw)
end)

packet.outgoing:register(function(raw)
    handle_packet('outgoing', raw)
end)

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
