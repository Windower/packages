local enumerable = {}

local enumerator_cache = setmetatable({}, {__mode = 'k'})

local helper = {
    no_args = function(...)
        return select('#', ...) == 0
    end,
    true_fn = function(...)
        return true
    end,
    equal = function(v1, v2)
        return v1 == v2
    end,
    add = function(x, y)
        return x + y
    end,
    min = function(x, y)
        return x < y and x or y
    end,
    max = function(x, y)
        return x > y and x or y
    end,
}

enumerable.enumerate = function(t)
    local iterator, table, key = pairs(t)
    return function(t, k)
        local key, value = iterator(t, k)
        return value, key
    end, table, key
end

enumerable.count = function(t, fn)
    fn = fn == nil and helper.true_fn or fn

    local count = 0
    for _, v in pairs(t) do
        if fn(v) == true then
            count = count + 1
        end
    end

    return count
end

enumerable.any = function(t, fn)
    fn = fn == nil and helper.true_fn or fn

    for _, v in pairs(t) do
        if fn(v) == true then
            return true
        end
    end

    return false
end

enumerable.all = function(t, fn)
    fn = fn == nil and helper.true_fn or fn

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

enumerable.first = function(t, fn)
    fn = fn == nil and helper.true_fn or fn

    for k, v in pairs(t) do
        if fn(v, k, t) == true then
            return v
        end
    end

    return nil
end

enumerable.last = function(t, fn)
    fn = fn == nil and helper.true_fn or fn

    local res
    for k, v in pairs(t) do
        if fn(v, k, t) == true then
            res = v
        end
    end

    return res
end

enumerable.single = function(t, fn)
    fn = fn == nil and helper.true_fn or fn

    local res
    for k, v in pairs(t) do
        if fn(v, k, t) == true then
            if res ~= nil then
                return nil
            else
                res = v
            end
        end
    end

    return res
end

enumerable.sequence_equal = function(t, compare, fn)
    fn = fn == nil and helper.equal or fn

    local iterator, table, key = pairs(t)
    local value
    key, value = iterator(table, key)
    for compare_key, compare_value in pairs(compare) do
        if key == nil or compare_value ~= value then
            return false
        end
        key, value = iterator(table, key)
    end

    return key == nil
end

enumerable.element_at = function(t, index)
    local count = 0
    for _, v in pairs(t) do
        count = count + 1
        if count == index then
            return v
        end
    end

    return nil
end

enumerable.aggregate = function(t, initial, accumulator, selector)
    local initialized = accumulator ~= nil
    accumulator = initialized and accumulator or initial

    local iterator, table, key = pairs(t)
    local res = initialized and initial or nil
    if not initialized then
        key, res = iterator(table, key)
    end

    for key, el in iterator, table, key do
        res = accumulator(res, el, key, t)
    end

    return selector ~= nil and selector(res) or res
end

enumerable.sum = function(t, fn)
    fn = fn == nil and helper.add or fn
    return t:aggregate(fn)
end

enumerable.min = function(t, fn)
    fn = fn == nil and helper.min or fn
    return t:aggregate(fn)
end

enumerable.max = function(t, fn)
    fn = fn == nil and helper.max or fn
    return t:aggregate(fn)
end

enumerable.average = function(t, fn)
    return t:sum(fn) / #t
end

enumerable.totable = function(t)
    local arr = {}
    local key = 0
    for _, el in pairs(t) do
        key = key + 1
        arr[key] = el
    end

    return arr
end

local lazy_functions = {
    select = function(constructor, original, fn)
        local res = constructor()

        enumerator_cache[res] = function(res)
            local iterator, table, key = pairs(original)
            return function(t, k)
                local key, value = iterator(t, k)
                if key == nil then
                    return nil, nil
                end

                return key, fn(value, key, original)
            end, table, key
        end

        return res
    end,
    select_many = function(constructor, original, fn)
        local res = constructor()

        enumerator_cache[res] = function(res)
            local iterator, table, key = pairs(original)
            local outer_key, inner, inner_iterator, inner_table, inner_key
            return function(t, k)
                local value

                if outer_key == nil then
                    table = t
                    outer_key = k
                end

                if inner_key ~= nil then
                    inner_key, value = inner_iterator(inner, inner_key)
                end

                while inner_key == nil do
                    outer_key, inner = iterator(table, outer_key)
                    if outer_key == nil then
                        return nil, nil
                    end

                    inner = fn(inner, outer_key, table)
                    inner_iterator, inner_table, inner_key = pairs(inner)

                    inner_key, value = inner_iterator(inner, inner_key)
                end

                return inner_key, value
            end, table, key
        end

        return res
    end,
    where = function(constructor, original, fn)
        local res = constructor()

        enumerator_cache[res] = function(res)
            local iterator, table, key = pairs(original)
            return function(t, k)
                local key, value = iterator(t, k)
                while key ~= nil and not fn(value, key, original) do
                    key, value = iterator(t, key)
                end

                return key, value
            end, table, key
        end

        return res
    end,
    take = function(constructor, original, max)
        local res = constructor()

        enumerator_cache[res] = function(res)
            local iterator, table, key = pairs(original)
            local count = 0
            return function(t, k)
                count = count + 1
                if count > max then
                    return nil, nil
                end

                return iterator(t, k)
            end, table, key
        end

        return res
    end,
    take_while = function(constructor, original, condition)
        local res = constructor()

        enumerator_cache[res] = function(res)
            local iterator, table, key = pairs(original)
            return function(t, k)
                local key, value = iterator(t, k)
                if not condition(value, key, t) then
                    return nil, nil
                end

                return key, value
            end, table, key
        end

        return res
    end,
    skip = function(constructor, original, count)
        local res = constructor()

        enumerator_cache[res] = function(res)
            local iterator, table, key = pairs(original)
            local count = count
            return function(t, k)
                local key, value = iterator(t, k)
                while key ~= nil and count > 0 do
                    count = count - 1
                    key, value = iterator(t, key)
                end

                return key, value
            end, table, key
        end

        return res
    end,
    skip_while = function(constructor, original, count)
        local res = constructor()

        enumerator_cache[res] = function(res)
            local iterator, table, key = pairs(original)
            return function(t, k)
                local key, value = iterator(t, k)
                while key ~= nil and condition(value, key, t) do
                    key, value = iterator(t, key)
                end

                return key, value
            end, table, key
        end

        return res
    end,
    of_type = function(constructor, original, compare)
        local res = constructor()

        enumerator_cache[res] = function(res)
            local iterator, table, key = pairs(original)
            return function(t, k)
                local key, value = iterator(t, k)
                while key ~= nil and type(value) ~= compare do
                    key, value = iterator(t, key)
                end

                return key, value
            end, table, key
        end

        return res
    end,
    concat = function(constructor, original, other)
        local res = constructor()

        enumerator_cache[res] = function(res)
            local iterator, table, key = pairs(original)
            local first = true
            return function(t, k)
                local value
                key, value = iterator(table, key)
                if key == nil then
                    if not first then
                        return nil, nil
                    else
                        iterator, table, key = pairs(other)
                        first = false
                        key, value = iterator(table, key)
                    end
                end

                return key, value
            end, table, key
        end

        return res
    end,
}

local dependent_functions = {
    add = {
        copy = function(constructor, add, original)
            local res = constructor()
            for key, el in pairs(original) do
                add(res, el, key)
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

local build_index_table = function(constructor, proxies)
    local index_table = {}

    for name, fn in pairs(proxies) do
        index_table[name] = fn
    end

    for name, fn in pairs(enumerable) do
        index_table[name] = fn
    end

    for name, fn in pairs(lazy_functions) do
        index_table[name] = function(...)
            return fn(constructor, ...)
        end
    end

    for proxy_name, proxy in pairs(proxies) do
        for name, fn in pairs(dependent_functions[proxy_name]) do
            index_table[name] = function(...)
                return fn(constructor, proxy, ...)
            end
        end
    end

    return index_table
end

local find_index = function(t, k, index_table, original, constructor)
    if original == nil and index_table[k] ~= nil then
        return index_table[k]
    end

    if original == nil and enumerator_cache[t] ~= nil then
        return constructor(t)[k]
    end

    if type(original) ~= 'function' or enumerator_cache[t] == nil then
        return original
    end

    return function(_, ...)
        return original(constructor(t), ...)
    end
end

local operators = {
    unary = {
        '__len',
        '__unm',
        '__unp',
        '__call',
        '__tostring',
    },
    binary = {
        '__lt',
        '__le',
        '__eq',
        '__add',
        '__sub',
        '__mul',
        '__div',
        '__mod',
        '__pow',
        '__concat',
    }
}

local index_cache = {}
local configure_metatable = function(meta, name)
    -- Create default/copy constructor if none available
    if meta.__create == nil then
        meta.__create = function(t)
            local res = {}
            local key = 0
            for _, el in pairs(t or {}) do
                -- Cannot use __add_element here for reasons I may some day remember
                key = key + 1
                res[key] = el
            end
            return setmetatable(res, meta)
        end
    end

    -- Create default addition function
    if meta.__add_element == nil then
        meta.__add_element = function(t, v, k)
            rawset(t, k, v)
        end
    end

    -- Create default removal function
    if meta.__remove_key == nil then
        meta.__remove_key = function(t, k)
            rawset(t, k, nil)
        end
    end

    local constructor = meta.__create
    local add = meta.__add_element
    local remove = meta.__remove_key

    local index_table = build_index_table(constructor, {
        add = add,
        remove = remove,
    })
    index_cache[#index_cache + 1] = index_table

    -- __index
    local original_index = meta.__index
    local index_type = type(original_index)
    --TODO: Cache find_index result? local table with __index metamethod that sets used keys?
    if index_type == 'nil' then
        meta.__index = function(t, k)
            return find_index(t, k, index_table, nil, constructor)
        end
    elseif index_type == 'table' then
        meta.__index = function(t, k)
            return find_index(t, k, index_table, original_index[k], constructor)
        end
    elseif index_type == 'function' then
        meta.__index = function(t, k)
            return find_index(t, k, index_table, original_index(t, k), constructor)
        end
    else
        error(('Unknown index_type: %s'):format(type))
    end

    -- __len
    if meta.__len == nil then
        meta.__len = enumerable.count
    end

    -- Lazy evaluation
    -- If __pairs is not provided, it should default to pairs, but we can't use pairs itself
    -- or it will go to the __pairs metamethod again and infinitely recurse, so we provide a
    -- custom pairs implementation
    local enumerator = meta.__pairs or function(t)
        return next, t, nil
    end
    meta.__pairs = function(t)
        return (enumerator_cache[t] or enumerator)(t)
    end

    -- Implement toX function as a constructor call
    if name ~= nil then
        local key = 'to' .. name
        enumerable[key] = constructor
        for _, cached_index_table in pairs(index_cache) do
            cached_index_table[key] = constructor
        end
    end

    -- Evaluate table for operators
    local is_native = function(fn)
        for _, enumerable_fn in pairs(index_table) do
            if enumerable_fn == fn then
                return false
            end
        end

        return true
    end
    for _, operator in pairs(operators.unary) do
        local fn = meta[operator]
        if fn ~= nil and is_native(fn) then
            meta[operator] = function(t, ...)
                t = enumerator_cache[t] ~= nil and constructor(t) or t
                return fn(t, ...)
            end
        end
    end
    for _, operator in pairs(operators.binary) do
        local fn = meta[operator]
        if fn ~= nil and is_native(fn) then
            meta[operator] = function(t1, t2, ...)
                t1 = enumerator_cache[t1] ~= nil and constructor(t1) or t1
                t2 = enumerator_cache[t2] ~= nil and constructor(t2) or t2
                return fn(t1, t2, ...)
            end
        end
    end

    -- Hack to remove second table argument to __len
    if meta.__len ~= nil then
        local len = meta.__len
        meta.__len = function(t)
            return len(t)
        end
    end

    return meta.__create
end

local empty_constructor = configure_metatable({})

local result = {
    init_type = configure_metatable,
    wrap = function(t)
        --TODO: Or just ignore existing metatable? Or copy? Or initialize fully?
        assert(getmetatable(t) == nil, 'Cannot wrap enumerable around existing metatable')

        return empty_constructor(t)
    end,
}

for name, fn in pairs(enumerable) do
    result[name] = fn
end

for name, fn in pairs(lazy_functions) do
    result[name] = function(t, ...)
        return fn(getmetatable(t).__create, t, ...)
    end
end

return result

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
