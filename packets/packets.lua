local event = require('event')
local shared = require('shared')
local table = require('table')
local string = require('string')

local fetch = shared.get('packet_service', 'packets')

local get_last = function(_, path)
    return get_last(path)
end

local make_event = function(_, path)
    return make_event(path)
end

local make_new = function(_, path, values)
    return make_new(path, values)
end

local inject = function(_, path, values)
    inject(path, values)
end

local registry = {}

local fns = {}

local make_table
local packet_meta = {
    __index = function(t, k)
        if k == 'last' then
            return fetch:call(get_last, t.path)
        end

        return make_table(t.path .. '/' .. tostring(k))
    end,
}

local register_path = function(path, fn)
    local events = registry[path]
    if not events then
        events = {}
        registry[path] = events
    end
    local event = fetch:call(make_event, path)
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
    for indices, fn in pairs(init_table) do
        local path = t.path .. '/' .. table.concat(indices, '/')

        register_path(path, fn)

        paths[#paths + 1] = { path = path, fn = fn }
    end

    local lasts = {}
    for _, path in ipairs(paths) do
        local last = fetch:call(get_last, path.path)
        if last then
            lasts[#lasts + 1] = { packet = last, fn = path.fn }
        end
    end

    table.sort(lasts, function(l1, l2)
        return l1.packet.timestamp < l2.packet.timestamp
    end)

    for _, last in ipairs(lasts) do
        last.fn(last.packet)
    end
end

fns.new = function(t, values)
    return setmetatable(fetch:call(make_new, t.path, values), {
        __index = function(p, k)
            if k == 'inject' then
                fetch:call(inject, t.path, p)
            end
        end,
    })
end

fns.inject = function(t, values)
    fetch:call(inject, t.path, values)
end

do
    local string_find = string.find

    make_table = function(path)
        local id_path = string_find(path, '/', 2)
        return setmetatable({
            path = path,
            register = fns.register,
            unregister = fns.unregister,
            register_init = fns.register_init,
            new = id_path and fns.new,
            inject = id_path and fns.inject,
        }, packet_meta)
    end
end

return make_table('')

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
