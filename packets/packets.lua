local event = require('event')
local shared = require('shared')
local table = require('table')
local string = require('string')

local client = shared.get('packet_service', 'packets')

local get_last = function(_, path)
    return get_last(path)
end

local get_lasts = function(_, path)
    return get_lasts(path)
end

local make_event = function(_, path)
    return make_event(path)
end

local inject = function(_, path, values)
    inject(path, values)
end

local block = function(_)
    block()
end

local update = function(_, p)
    update(p)
end

local registry = {}

local fns = {}

local register_path = function(path, fn)
    local events = registry[path]
    if not events then
        events = {}
        registry[path] = events
    end
    local event = client:call(make_event, path)
    events[fn] = event
    event:register(fn)
end

fns.register = function(t, fn)
    register_path(t.path, fn)
end

fns.unregister = function(t, fn)
    registry[t.path][fn] = nil
end

fns.register_init = function(t, init_table)
    local paths = {}
    local path_count = 0
    for indices, fn in pairs(init_table) do
        local path = t.path .. '/' .. table.concat(indices, '/')

        register_path(path, fn)

        path_count = path_count + 1
        paths[path_count] = { path = path, fn = fn }
    end

    local lasts = {}
    local lasts_count = 0
    for i = 1, #paths do
        local path = paths[i]
        local lasts_path = client:call(get_lasts, path.path)
        for j = 1, #lasts_path do
            local packet = lasts_path[j]
            lasts_count = lasts_count + 1
            lasts[lasts_count] = { packet = packet, fn = path.fn , timestamp = packet._info.timestamp }
        end
    end

    table.sort(lasts, function(l1, l2)
        return l1.timestamp < l2.timestamp
    end)

    for i = 1, #lasts do
        local last = lasts[i]
        last.fn(last.packet)
    end
end

fns.inject = function(t, values)
    client:call(inject, t.path, values)
end

local make_table = function(path, allow_injection)
    return {
        path = path,
        register = fns.register,
        unregister = fns.unregister,
        register_init = fns.register_init,
        inject = allow_injection and fns.inject or nil,
    }
end

local packet_meta
packet_meta = {
    __index = function(t, k)
        if k == 'last' then
            return client:call(get_last, t.path)
        end

        return setmetatable(make_table(t.path .. '/' .. tostring(k), true), packet_meta)
    end,
}

local packets = make_table('', false)

packets.incoming = setmetatable(make_table('/incoming', false), packet_meta)
packets.outgoing = setmetatable(make_table('/outgoing', false), packet_meta)
packets.block = function()
    client:call(block)
end
packets.update = function(p)
    client:call(update, p)
end

return packets

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
