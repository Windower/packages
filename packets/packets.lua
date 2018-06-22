local event = require('event')
local shared = require('shared')

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

fns.register = function(t, fn)
    local base = get_recursive(registry, unpack(t.path))
    local event = fetch:call(make_event, unpack(t.path))
    base.fns[fn] = event
    event:register(fn)
end

fns.unregister = function(t, fn)
    local base = get_recursive(registry, unpack(t.path))
    base.fns[fn] = nil
end

fns.new = function(t, values)
    error('Not yet implemented.')
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
        new = fns.new,
    }, packet_meta)
end

return make_table({ path = {} })
