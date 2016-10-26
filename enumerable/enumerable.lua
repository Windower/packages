local enumerable = {}

enumerable.enumerate = function(t)
    return function(t, k)
        local key, value = next(t, k)
        return value, key
    end, t, nil
end

enumerable.count = function(t, ...)
    local count = 0

    if select('#', ...) == 0 or type(...) == 'table' then
        for _ in pairs(t) do
            count = count + 1
        end
    else
        for _, el in pairs(t) do
            if (...)(el) == true then
                count = count + 1
            end
        end
    end

    return count
end

enumerable.any = function(t, ...)
    if select('#', ...) == 0 then
        for _ in pairs(t) do
            return true
        end

        return false
    end

    for _, v in pairs(t) do
        if (...)(v) == true then
            return true
        end
    end

    return false
end

enumerable.all = function(t, fn)
    for _, v in pairs(t) do
        if fn(v) == false then
            return false
        end
    end

    return true
end

enumerable.contains = function(t, search)
    for _, el in pairs(t) do
        if el == search then
            return true
        end
    end

    return false
end

enumerable.to_table = function(t)
    local arr = {}
    local key = 0
    for _, el in pairs(t) do
        key = key + 1
        arr[key] = el
    end

    return arr
end

enumerable.aggregate = function(t, fn, ...)
    local initialized = select('#', ...) > 0
    local res = ...

    for key, el in pairs(t) do
        if not initialized then
            res = el
            initialized = true
        else
            res = fn(res, el, key, t)
        end
    end

    return res
end

local redirect = {
    add = {
        copy = function(constructor, add, t)
            local res = constructor()
            for _, el in pairs(t) do
                add(res, el)
            end

            return res
        end,
        select = function(constructor, add, t, fn)
            local res = constructor()

            for key, el in pairs(t) do
                add(res, fn(el, key, t))
            end

            return res
        end,
        where = function(constructor, add, t, fn)
            local res = constructor()

            for key, el in pairs(t) do
                if fn(el, key, t) then
                    add(res, el)
                end
            end

            return res
        end,
    },
    remove = {
        clear = function(constructor, remove, t)
            for key in pairs(t) do
                remove(t, key)
            end

            return t
        end,
    },
}

local build_index = function(constructor, proxies)
    local index = {}

    for name, fn in pairs(enumerable) do
        index[name] = fn
    end

    if constructor ~= nil then
        for proxy_name, proxy in pairs(proxies) do
            for name, fn in pairs(redirect[proxy_name]) do
                index[name] = function(...)
                    return fn(constructor, proxy, ...)
                end
            end
        end
    end

    return index
end

return function(meta)
    local index = build_index(meta.__create, {
        add = meta.__add_element,
        remove = meta.__remove_key,
    })

    -- __index
    local original = meta.__index
    local index_type = type(original)
    if index_type == 'nil' then
        meta.__index = index
    elseif index_type == 'table' then
        meta.__index = function(t, k)
            return original[k] or index[k]
        end
    elseif index_type == 'function' then
        meta.__index = function(t, k)
            return original(t, k) or index[k]
        end
    else
        error(('Unknown indexing index_type: '):format(type))
    end

    -- __len
    if meta.__len == nil then
        meta.__len = type(meta.__index) == 'table' and meta.__index.count or meta.__index(nil, 'count')
    end
end

