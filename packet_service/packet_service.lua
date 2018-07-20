local event = require('event')
local ffi = require('ffi')
local packet = require('packet')
local shared = require('shared')
local string = require('string')
local math = require('math')
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

local parse_single
do
    local math_floor = math.floor
    local ffi_copy = ffi.copy
    local ffi_new = ffi.new

    local amend_cdata
    amend_cdata = function(packet, cdata, ftype)
        local count = ftype.count
        if count then
            for i = 0, count - 1 do
                local inner_value = cdata[i]
                if type(inner_value) == 'cdata' then
                    local inner = {}
                    packet[i] = inner
                    amend_cdata(inner, inner_value, ftype.base)
                else
                    packet[i] = inner_value
                end
            end
            return
        end

        for key, value in pairs(cdata) do
            if type(value) == 'cdata' then
                local inner = {}
                packet[key] = inner
                amend_cdata(inner, value, ftype.fields[key].type)
            else
                packet[key] = value
            end
        end
    end

    parse_single = function(packet, ptr, ftype, size)
        if ftype == nil then
            return
        end

        if ftype.multiple == nil then
            local instance
            if ftype.var_size then
                instance = ffi_new(ftype.name, math_floor((size - ftype.size) / ftype.var_size))
            else
                instance = ffi_new(ftype.name)
            end
            ffi_copy(instance, ptr, ftype.size)

            amend_cdata(packet, instance, ftype)
            return
        end

        local base = ftype.base
        local indices = {parse_single(packet, ptr, base, size)}
        local size_diff = base.size
        ptr = ptr + size_diff
        size = size - size_diff

        do
            local lookups = ftype.lookups
            local base_index = #indices
            for i = 1, #lookups do
                indices[base_index + i] = packet[lookups[i]]
            end
        end

        local new_type = ftype
        for i = 1, #indices do
            local index = indices[i]
            new_type = new_type[index]

            if new_type == nil then
                return unpack(indices)
            end
        end

        do
            local new_indices = {parse_single(packet, ptr, new_type, size)}
            local base_index = #indices
            for i = 1, #new_indices do
                indices[base_index + i] = new_indices[i]
            end
        end

        return unpack(indices)
    end
end

local history_lookup = {}
local events_lookup = {}

packets.env = {
    get_last = function(...)
        local history = history
        for i = 1, select('#', ...) do
            history = rawget(history, select(i, ...))
            if not history then
                return nil
            end
        end

        return history_lookup[history]
    end,
    make_event = function(...)
        local registry = registry
        for i = 1, select('#', ...) do
            registry = registry[select(i, ...)]
        end

        local event = event.new()
        local events = events_lookup[registry]
        if not events then
            events = {}
            events_lookup[registry] = events
        end
        events[#events + 1] = event

        return event
    end,
}

local trigger_events = function(registry, packet)
    local events = events_lookup[registry]
    if not events then
        return
    end

    for i = 1, #events do
        events[i]:trigger(packet)
    end
end

local make_timestamp
do
    local os_time = os.time

    local last_time = os_time()
    local now_count = 0

    make_timestamp = function()
        local now = os_time()
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
    local data = raw.data

    local packet = {
        id = id,
        direction = direction,
        data = data,
        blocked = raw.blocked,
        modified = raw.modified,
        injected = raw.injected,
        timestamp = make_timestamp(),
    }

    if id == 0x037 then x = true end
    local indices = {direction, id, parse_single(packet, char_ptr(data), types[direction][id], #data)}
    x = false

    local registry = registry
    local history = history

    trigger_events(registry, packet)
    history_lookup[history] = packet

    for i = 1, #indices do
        local index = indices[i]

        registry = registry[index]
        history = history[index]

        trigger_events(registry, packet)
        history_lookup[history] = packet
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
