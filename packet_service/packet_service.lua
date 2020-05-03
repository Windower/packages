local core = {
    packet = require('core.packet'),
}
local event = require('core.event')
local file = require('file')
local ffi = require('ffi')
local os = require('os')
local serializer = require('core.serializer')
local server = require('shared.server')
local channel = require('core.channel')
local string = require('string')
local struct = require('struct')
local windower = require('core.windower')

local loadstring = loadstring
local pairs = pairs
local tonumber = tonumber
local tostring = tostring

packets_server = channel.new('packets')
types_server = channel.new('types')

local packet_types
local parse_types
do
    local file_new = file.new

    local type_file = file_new(windower.package_path .. '\\types.lua')
    local file_read = type_file.read

    parse_types = function()
        packet_types = loadstring(file_read(type_file))()
    end
end

parse_types()

types_server.data = packet_types

local empty_ftype = struct.struct({empty = true}, {})

local registry = {}
local history = {}
local ftype_map = {
    current = struct.struct({
        modified        = {0x000, struct.data(0x100)},
        modified_size   = {0x100, struct.int32},
        original        = {struct.data(0x100)},
        original_size   = {struct.int32},
        id              = {struct.int32},
        direction       = {struct.string(0x10)},
        timestamp       = {struct.double},
        blocked         = {struct.bool},
        injected        = {struct.bool},
        sequence_counter= {struct.int32},
        path            = {struct.string(0x100)},
    }),
    injection = struct.struct({
        data            = {0x000, struct.data(0x100)},
        data_size       = {0x100, struct.int32},
        id              = {struct.int32},
        direction       = {struct.string(0x10)},
    })
}

packets_server.env = {}

do
    local serializer_serialize = serializer.serialize
    local string_sub = string.sub
    local string_find = string.find

    packets_server.env.get_ftype = function(path)
        local ftype = ftype_map[path]

        if not ftype then
            if #path < 10 then
                ftype = empty_ftype
            else
                local direction = string_sub(path, 2, 9)
                local slash_index = string_find(path, '/', 11, true)
                local id = tonumber(string_sub(path, 11, slash_index and slash_index - 1))

                ftype = packet_types[direction][id] or empty_ftype

                local types = ftype.types
                while slash_index and types do
                    local start_index = slash_index + 1
                    slash_index = string_find(path, '/', start_index, true)
                    local key = tonumber(string_sub(path, start_index, slash_index and slash_index - 1))

                    local sub_ftype = types[key]
                    if not sub_ftype then
                        break
                    end

                    ftype = sub_ftype
                    types = ftype.types
                end

                if types then
                    ftype = ftype.base
                end
            end

            ftype_map[path] = ftype
        end

        return serializer_serialize(ftype, true)
    end
end

packets_server.env.get_last = function(path)
    return history[path].payload
end

do
    local string_sub = string.sub

    packets_server.env.get_lasts = function(start_path)
        local found = {}
        local res = {}
        local res_count = 0
        for path, entry in pairs(history) do
            if start_path == path or start_path .. '/' == string_sub(path, 1, #start_path + 1) and not found[entry] then
                res_count = res_count + 1
                res[res_count] = entry.payload
                found[entry] = true
            end
        end
        return res
    end
end

do
    local event_new = event.new

    packets_server.env.make_event = function(path)
        local events = registry[path]
        if not events then
            events = {}
            registry[path] = events
        end

        local new_event = event_new()
        events[#events + 1] = new_event

        return new_event
    end
end

do
    local ffi_cast = ffi.cast
    local ffi_string = ffi.string
    local packet_inject_incoming = core.packet.inject_incoming
    local packet_inject_outgoing = core.packet.inject_outgoing
    local packet_new = core.packet.new

    local injection_ptr = server.new_ptr(ftype_map.injection)
    local injection_address = tonumber(ffi_cast('intptr_t', injection_ptr))

    packets_server.env.get_injection_address = function()
        return injection_address
    end

    packets_server.env.inject = function()
        local p = packet_new(injection_ptr.id, ffi_string(injection_ptr.data, injection_ptr.data_size))
        if injection_ptr.direction == 'incoming' then
            packet_inject_incoming(p)
        else
            packet_inject_outgoing(p)
        end
    end
end

local handle_packet
do
    local ffi_cast = ffi.cast
    local ffi_copy = ffi.copy
    local ffi_string = ffi.string
    local server_new_ptr = server.new_ptr

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

    local current_type = ftype_map.current
    local current_ptr = server_new_ptr(current_type)
    local current = current_ptr[0]
    local current_size = current_type.size
    local current_address = tonumber(ffi_cast('intptr_t', current_ptr))
    local buffer = ffi_cast('char*', current_ptr) + current_type.fields.modified.position

    packets_server.env.get_current_address = function()
        return current_address
    end

    handle_packet =  function(direction, raw)
        local id = raw.id
        local data = raw.data

        current.modified = data
        current.modified_size = #data
        current.original = data
        current.original_size = #data
        current.timestamp = make_timestamp()
        current.id = id
        current.direction = direction
        current.blocked = raw.blocked
        current.injected = raw.injected
        current.sequence_counter = raw.sequence_counter

        local ftype = packet_types[direction][id] or empty_ftype
        local types = ftype.types
        while types do
            local base = ftype.base
            local cdata = ffi_cast(base.name .. '*', buffer)[0]
            ftype = types[cdata[ftype.key]] or base
            types = ftype.types
        end

        local cdata = ffi_cast(ftype.name .. '*', buffer)[0]

        local paths
        local full_path
        local paths_count = 3
        do
            local dir_path = '/' .. direction
            local id_path = dir_path .. '/' .. id
            paths = {
                '',
                dir_path,
                id_path,
            }

            full_path = id_path
            local finfo = ftype and ftype.info
            local cache = finfo and finfo.cache
            if cache then
                for i = 1, #cache do
                    full_path = full_path .. '/' .. tostring(cdata[cache[i]])
                    paths_count = paths_count + 1
                    paths[paths_count] = full_path
                end
            end
        end

        current.path = full_path

        for i = 1, paths_count do
            local events = registry[paths[i]]
            if events then
                for j = 1, #events do
                    events[j]:trigger()
                end
            end
        end

        local entry_ptr = server_new_ptr(current_type)
        ffi_copy(entry_ptr, current_ptr, current_size)
        local entry = {
            ptr = entry_ptr,
            payload = {
                address = tonumber(ffi_cast('intptr_t', entry_ptr)),
                path = full_path,
            },
        }

        for i = 1, paths_count do
            history[paths[i]] = entry
        end

        if current.blocked then
            raw.blocked = true
        end

        local modified = ffi_string(buffer, current.modified_size)
        if modified ~= data then
            raw.data = modified
        end
    end
end

core.packet.incoming:register(function(raw)
    handle_packet('incoming', raw)
end)

core.packet.outgoing:register(function(raw)
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
