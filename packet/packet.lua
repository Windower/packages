local ffi = require('ffi')
local channel = require('core.channel')
local serializer = require('core.serializer')
local string = require('string')
local client = require('shared.client')
local table = require('table')

local packet_client = channel.get('packet_service', 'packets')

local get_ftype = function(_, path)
    return get_ftype(path)
end

local get_last = function(_, path)
    return get_last(path)
end

local get_lasts = function(_, path)
    return get_lasts(path)
end

local make_event = function(_, path)
    return make_event(path)
end

local inject = function(_)
    inject()
end

local pairs = pairs
local setmetatable = setmetatable
local tonumber = tonumber
local tostring = tostring

local type_map
do
    local client_configure = client.configure
    local serializer_deserialize = serializer.deserialize

    type_map = setmetatable({}, {
        __index = function(t, k)
            local ftype = serializer_deserialize(packet_client:call(get_ftype, k))
            client_configure(ftype)
            t[k] = ftype
            return ftype
        end,
    })
end

local registry = {}
local path_cache = {}
local info_cache = {}
local fragments_cache = {}

local fns = {}

local get_packet
do
    local ffi_cast = ffi.cast
    local ffi_typeof = ffi.typeof

    local current_ftype = type_map.current
    local modified_offset = current_ftype.fields.modified.position
    local current_type = ffi_typeof(current_ftype.name .. '*')

    get_packet = function(address, path)
        return ffi_cast(type_map[path].name .. '*', address + modified_offset)[0], ffi_cast(current_type, address)[0]
    end
end

local register_path
do
    local ffi_cast = ffi.cast

    local get_current_address = function()
        return get_current_address()
    end

    local current_address = packet_client:call(get_current_address)
    local current = ffi_cast(type_map.current.name .. '*', current_address)[0]

    register_path = function(path, fn)
        local events = registry[path]
        if not events then
            events = {}
            registry[path] = events
        end

        local wrapped = function()
            fn(get_packet(current_address, current.path))
        end

        local event = packet_client:call(make_event, path)
        events[fn] = {
            event = event,
            fn = wrapped,
        }
        event:register(wrapped)
    end
end

fns.register = function(t, fn)
    register_path(path_cache[t], fn)
end

fns.unregister = function(t, fn)
    local entry = registry[path_cache[t]][fn]
    entry.event:unregister(entry.fn)
end

do
    local table_concat = table.concat
    local table_sort = table.sort

    fns.register_init = function(t, init_table)
        local root_path = path_cache[t]
        local paths = {}
        local path_count = 0
        for indices, fn in pairs(init_table) do
            local path = root_path .. '/' .. table_concat(indices, '/')

            register_path(path, fn)

            path_count = path_count + 1
            paths[path_count] = {
                path = path,
                fn = fn,
            }
        end

        local lasts = {}
        local lasts_count = 0
        for i = 1, #paths do
            local path = paths[i]
            local last_entries = packet_client:call(get_lasts, path.path)
            for j = 1, #last_entries do
                local entry = last_entries[j]
                local packet, info = get_packet(entry.address, entry.path)
                lasts_count = lasts_count + 1
                lasts[lasts_count] = {
                    packet = packet,
                    info = info,
                    fn = path.fn ,
                    timestamp = info.timestamp,
                }
            end
        end

        table_sort(lasts, function(l1, l2)
            return l1.timestamp < l2.timestamp
        end)

        for i = 1, #lasts do
            local last = lasts[i]
            last.fn(last.packet, last.info)
        end
    end
end

do
    local ffi_cast = ffi.cast
    local ffi_fill = ffi.fill

    local injection_ptr = ffi_cast(type_map.injection.name .. '*', packet_client:call(function()
        return get_injection_address()
    end))
    local injection = injection_ptr[0]
    local injection_size = type_map.injection.size
    local buffer = ffi_cast('char*', injection_ptr) + type_map.injection.fields.data.position

    fns.inject = function(t, values)
        local info = info_cache[t]
        local ftype = info.ftype

        ffi_fill(injection_ptr, injection_size)

        injection.data_size = ftype.size
        injection.direction = info.direction
        injection.id = info.id

        local cdata = ffi_cast(ftype.name .. '*', buffer)[0]
        if values then
            for key, value in pairs(values) do
                cdata[key] = value
            end
        end

        local fragments = fragments_cache[t]
        if fragments then
            for key, value in pairs(fragments) do
                cdata[key] = value
            end
        end

        packet_client:call(inject)
    end
end

fns.last = function(t)
    local last = packet_client:call(get_last, path_cache[t])
    if not last then
        return nil, nil
    end
    return get_packet(last.address, last.path)
end

local make_error = function(message)
    return function()
        error(message, 2)
    end
end

local make_table
do
    local string_find = string.find
    local string_sub = string.sub

    make_table = function(path, parent, fragment)
        local ftype = type_map[path]

        local specific = ftype.info.empty ~= true
        local result = {
            register = fns.register,
            unregister = fns.unregister,
            register_init = fns.register_init,
            inject = specific and fns.inject or make_error('Cannot inject path: ' .. path),
            last = specific and fns.last or make_error('Cannot retrieve last path: ' .. path),
        }

        if specific then
            local info = {}

            info.ftype = ftype

            info.direction = string_sub(path, 2, 9)
            local slash_index = string_find(path, '/', 11, true)
            info.id = tonumber(string_sub(path, 11, slash_index and slash_index - 1))

            info_cache[result] = info
        end
        path_cache[result] = path

        if parent then
            local parent_ftype = type_map[path_cache[parent]]
            local parent_key = parent_ftype.info.key
            if parent_key then
                local fragments = {
                    [parent_key] = fragment,
                }

                local parent_fragments = fragments_cache[parent]
                if parent_fragments then
                    for key, value in pairs(parent_fragments) do
                        fragments[key] = value
                    end
                end

                fragments_cache[result] = fragments
            end
        end

        return result, specific
    end
end

local final_meta = function(path)
    return {
        __index = make_error('Cannot index path: ' .. path),
        __newindex = make_error('Cannot assign to path: ' .. path),
    }
end

local packet_meta
packet_meta = {
    __index = function(t, k)
        local path = path_cache[t] .. '/' .. tostring(k)
        if type(k) ~= 'number' then
            error('Invalid packet path: ' .. path)
        end

        local inner, specific = make_table(path, t, k)
        local value = setmetatable(inner, specific and final_meta(path) or packet_meta)
        rawset(t, k, value)
        return value
    end,
    __newindex = function(t, _, _)
        error('Cannot assign to path: ' .. path_cache[t])
    end,
}

local packet = setmetatable(make_table(''), packet_meta)

rawset(packet, 'incoming', setmetatable(make_table('/incoming'), packet_meta))
rawset(packet, 'outgoing', setmetatable(make_table('/outgoing'), packet_meta))
rawset(packet, 'types', type_map)

return packet

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
