local event = require('event')
local shared = require('shared')
local table = require('table')

local fetch = shared.get('packet_service', 'packets')

local get_last = function(_, ...)
    return get_last(...)
end

local make_event = function(_, ...)
    return make_event(...)
end

local nesting_meta
nesting_meta = {
    __index = function(t, k)
        local v = setmetatable({}, nesting_meta)
        t[k] = v
        return v
    end,
}

local registry = setmetatable({}, nesting_meta)

local get_recursive
get_recursive = function(base, ...)
    if select('#', ...) == 0 then
        return base
    end

    if base[...] == nil then
        base[...] = { fns = {} }
    end

    return get_recursive(base[...], select(2, ...))
end

local fns = {}

local make_table
local packet_meta = {
    __index = function(t, k)
        if k == 'last' then
            return fetch:call(get_last, unpack(t.path))
        end

        local new = make_table(t)
        new.path[#new.path + 1] = k
        return new
    end,
}

local register_path = function(path, fn)
    local base = get_recursive(registry, unpack(path))
    local event = fetch:call(make_event, unpack(path))
    base.fns[fn] = event
    event:register(fn)
end

fns.register = function(t, fn)
    register_path(t.path, fn)
end

fns.unregister = function(t, fn)
    local base = get_recursive(registry, unpack(t.path))
    base.fns[fn] = nil
end

fns.new = function(t, values)
    error('Not yet implemented.')
end

fns.register_init = function(t, init_table)
    local paths = {}
    for indices, fn in pairs(init_table) do
        local path = {}
        for i, index in ipairs(t.path) do
            path[i] = index
        end

        for _, index in ipairs(indices) do
            path[#path + 1] = index
        end

        register_path(path, fn)

        paths[#paths + 1] = { path = path, fn = fn }
    end

    local lasts = {}
    for _, path in ipairs(paths) do
        local last = fetch:call(get_last, unpack(path.path))
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

make_table = function(t)
    local path = t.path
    local new_path = {}
    for i = 1, #path do
        new_path[i] = path[i]
    end

    return setmetatable({
        path = new_path,
        register = fns.register,
        unregister = fns.unregister,
        register_init = fns.register_init,
        new = fns.new,
    }, packet_meta)
end

return make_table({ path = {} })

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
