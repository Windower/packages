local shared = require('shared')

local cache = setmetatable({}, { __mode = 'k' })

local shared_meta = {}

local new_nesting_table = function(path, client)
    local result = {}
    cache[result] = {
        path = path,
        client = client,
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
    local base_path_count = #base_path
    local path = {}
    for i = 1, base_path_count do
        path[i] = base_path[i]
    end
    path[base_path_count + 1] = k

    local client = info.client
    local data = client:call(get, unpack(path))
    return type(data) == 'table'
        and new_nesting_table(path, client)
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

        return key, new_nesting_table(path, client)
    end, info.path, nil
end

return {
    library = function(service_name)
        local data_client = shared.get(service_name, service_name:gsub('_service', '_data'))

        return new_nesting_table({}, data_client)
    end,
}
