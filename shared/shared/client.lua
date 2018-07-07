local shared = require('shared')
local event = require('event')
local windower = require('windower')
local string = require('string')

local cache = setmetatable({}, { __mode = 'k' })

local shared_meta = {}

local new_nesting_table = function(path, client, add, disable, init)
    local result = init or {}
    cache[result] = {
        path = path,
        client = client,
        add = add or {},
        disable = disable or {},
    }
    return setmetatable(result, shared_meta)
end

local get = function(data, ...)
    local result = data

    for i = 1, select('#', ...) do
        result = result[select(i, ...)]
    end

    return type(result) == 'table'
        and {}
        or result
end

shared_meta.__index = function(t, k)
    local info = cache[t]
    local base_path = info.path
    local client = info.client
    local add = info.add
    local disable = info.disable

    local added = add[k]
    if type(added) == 'function' then
        return client:call(added)
    end

    local disabled = disable[k]
    if type(disabled) == 'boolean' and disabled then
        return nil
    end

    local base_path_count = #base_path
    local path = {}
    for i = 1, base_path_count do
        path[i] = base_path[i]
    end
    path[base_path_count + 1] = k

    local data = client:call(get, unpack(path))
    return type(data) == 'table'
        and new_nesting_table(path, client, added)
        or data
end

local iterate = function(data, key, ...)
    local target = data

    for i = 1, select('#', ...) do
        target = target[select(i, ...)]
    end

    local next_key, next_value = next(target, key)
    if type(next_value) == 'table' then
        next_value = {}
    end

    return next_key, next_value
end

shared_meta.__pairs = function(t)
    local info = cache[t]
    local client = info.client
    local overrides = info.overrides
    return function(base_path, k)
        local key, value = client:call(iterate, k, unpack(base_path))
        if type(value) ~= 'table' then
            return key, value
        end

        local base_path_count = #base_path
        local path = {}
        for i = 1, base_path_count do
            path[i] = base_path[i]
        end
        path[base_path_count + 1] = k

        return key, new_nesting_table(path, client, overrides)
    end, info.path, nil
end

shared_meta.__newindex = function()
    error('Library table cannot be modified', 2)
end

return {
    new = function(name, options)
        options = options or {}

        local data_client = shared.get(name, name .. '_data')
        local events_client = shared.get(name, name .. '_events')

        local events = {}
        for name, raw_event in pairs(events_client:read()) do
            local slim_event = event.slim.new()
            events[name] = slim_event
            raw_event:register(function(...)
                slim_event:trigger(...)
            end)
        end

        return new_nesting_table({}, data_client, options.add, options.disable, events)
    end,
}
