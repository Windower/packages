local table = require('table')

local enumerable = {}

local enumerator_cache = setmetatable({}, {__mode = 'k'})
local empty_constructor

local add_fn = function(x, y)
    return x + y
end
local min_fn = function(x, y)
    return x < y and x or y
end
local max_fn = function(x, y)
    return x > y and x or y
end

enumerable.enumerate = function(t)
    local iterator, table, key = pairs(t)
    return function(t, k)
        local key, value = iterator(t, k)
        return value, key
    end, table, key
end

enumerable.count = function(t, fn)
    local count = 0
    if fn == nil  then
        for _ in pairs(t) do
            count = count + 1
        end
    else
        for _, v in pairs(t) do
            if fn(v) == true then
                count = count + 1
            end
        end
    end

    return count
end

enumerable.any = function(t, fn)
    if fn == nil then
        for _ in pairs(t) do
            return true
        end
    else
        for _, v in pairs(t) do
            if fn(v) == true then
                return true
            end
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

enumerable.first = function(t, fn)
    if fn == nil  then
        for _, v in pairs(t) do
            return v
        end
    else
        for _, v in pairs(t) do
            if fn(v) == true then
                return v
            end
        end
    end

    return nil
end

enumerable.last = function(t, fn)
    local res
    if fn == nil  then
        for _, v in pairs(t) do
            res = v
        end
    else
        for _, v in pairs(t) do
            if fn(v) == true then
                res = v
            end
        end
    end

    return res
end

enumerable.single = function(t, fn)
    local res
    if fn == nil  then
        for _, v in pairs(t) do
            if res ~= nil then
                return nil
            else
                res = v
            end
        end
    else
        for _, v in pairs(t) do
            if fn(v) == true then
                if res ~= nil then
                    return nil
                else
                    res = v
                end
            end
        end
    end

    return res
end

enumerable.sequence_equal = function(t, compare, fn)
    local iterator, table, key = pairs(t)
    local value
    key, value = iterator(table, key)
    if fn == nil  then
        for _, compare_value in pairs(compare) do
            if key == nil or compare_value ~= value then
                return false
            end
            key, value = iterator(table, key)
        end
    else
        for _, compare_value in pairs(compare) do
            if key == nil or not fn(compare_value, value) then
                return false
            end
            key, value = iterator(table, key)
        end
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

local enumerable_aggregate = enumerable.aggregate

enumerable.sum = function(t, fn)
    return enumerable_aggregate(t, fn or add_fn)
end

enumerable.min = function(t, fn)
    return enumerable_aggregate(t, fn or min_fn)
end

enumerable.max = function(t, fn)
    return enumerable_aggregate(t, fn or max_fn)
end

enumerable.average = function(t, fn)
    return enumerable_aggregate(t, fn or add_fn) / #t
end

enumerable.to_table = function(t)
    local arr = {}
    local count = 0
    for _, el in pairs(t) do
        count = count + 1
        arr[count] = el
    end

    return arr, count
end

local enumerable_to_table = enumerable.to_table

enumerable.group_by = function(t, fn)
    local elements, length = enumerable_to_table(t)

    local groups = {}
    for i = 1, length do
        local element = elements[i]
        local key = fn(element)
        local group = groups[key]
        if not group then
            group = empty_constructor()
            groups[key] = group
        end
        group:add(element)
    end

    return groups
end

enumerable.default_if_empty = function(t, element)
    local iterator, table, key = pairs(t)
    if iterator(table, key) == nil then
        return element
    end

    return t
end

local lazy_functions = {
    select = function(constructor, original, fn)
        local res = constructor()

        enumerator_cache[res] = function()
            local iterator, table, key = pairs(original)
            return function(t, k)
                local key, value = iterator(t, k)
                if key == nil then
                    return nil, nil
                end

                return key, fn(value)
            end, table, key
        end

        return res
    end,
    select_many = function(constructor, original, fn)
        local res = constructor()

        enumerator_cache[res] = function()
            local iterator, table, key = pairs(original)
            local outer_key, inner, inner_iterator, inner_key
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

                    inner = fn(inner)
                    inner_iterator, _, inner_key = pairs(inner)

                    inner_key, value = inner_iterator(inner, inner_key)
                end

                return inner_key, value
            end, table, key
        end

        return res
    end,
    where = function(constructor, original, fn)
        local res = constructor()

        enumerator_cache[res] = function()
            local iterator, table, key = pairs(original)
            return function(t, k)
                local key, value = iterator(t, k)
                while key ~= nil and not fn(value) do
                    key, value = iterator(t, key)
                end

                return key, value
            end, table, key
        end

        return res
    end,
    take = function(constructor, original, count)
        local res = constructor()

        enumerator_cache[res] = function()
            local iterator, table, key = pairs(original)
            local current_count = 0
            return function(t, k)
                current_count = current_count + 1
                if current_count > count then
                    return nil, nil
                end

                return iterator(t, k)
            end, table, key
        end

        return res
    end,
    take_while = function(constructor, original, condition)
        local res = constructor()

        enumerator_cache[res] = function()
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
    take_last = function(constructor, original, count)
        local res = constructor()

        enumerator_cache[res] = function()
            local elements, length = enumerable_to_table(original)
            local init = length - count
            return function(t, k)
                k = k + 1
                if k > length then
                    return nil, nil
                end

                return k, t[k]
            end, elements, init
        end

        return res
    end,
    skip = function(constructor, original, count)
        local res = constructor()

        enumerator_cache[res] = function()
            local iterator, table, key = pairs(original)
            local current_count = 0
            return function(t, k)
                local key, value = iterator(t, k)
                while key ~= nil and current_count < count do
                    current_count = current_count + 1
                    key, value = iterator(t, key)
                end

                return key, value
            end, table, key
        end

        return res
    end,
    skip_while = function(constructor, original, condition)
        local res = constructor()

        enumerator_cache[res] = function()
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
    skip_last = function(constructor, original, count)
        local res = constructor()

        enumerator_cache[res] = function()
            local elements, length = enumerable_to_table(original)
            return function(t, k)
                k = k + 1
                if k > length - count then
                    return nil, nil
                end

                return k, t[k]
            end, elements, 0
        end

        return res
    end,
    of_type = function(constructor, original, compare)
        local res = constructor()

        enumerator_cache[res] = function()
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

        enumerator_cache[res] = function()
            local iterator, table, key = pairs(original)
            local first = true
            return function(_, _)
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
    order_by = function(_, original, selector)
        local res = empty_constructor()

        enumerator_cache[res] = function()
            local elements, length = enumerable_to_table(original)

            local properties = {}
            for i = 1, length do
                local element = elements[i]
                properties[i] = {element, selector(element)}
            end

            table.sort(properties, function(lhs, rhs)
                return lhs[2] < rhs[2]
            end)

            return function(t, k)
                local key = k + 1
                if key > length then
                    return nil, nil
                end

                return key, t[key][1]
            end, properties, 0
        end

        return res
    end,
    order_by_descending = function(_, original, selector)
        local res = empty_constructor()

        enumerator_cache[res] = function()
            local elements, length = enumerable_to_table(original)

            local properties = {}
            for i = 1, length do
                local element = elements[i]
                properties[i] = {element, selector(element)}
            end

            table.sort(properties, function(lhs, rhs)
                return lhs[2] < rhs[2]
            end)

            return function(t, k)
                k = k + 1
                if k > length then
                    return nil, nil
                end

                return k, t[length - k + 1][1]
            end, properties, 0
        end

        return res
    end,
    distinct = function(constructor, original, compare)
        local res = constructor()

        if compare then
            enumerator_cache[res] = function()
                local found = {}
                local found_count = 0
                local iterator, table, key = pairs(original)
                return function(t, k)
                    local key = k
                    local value, exists
                    repeat
                        key, value = iterator(t, key)
                        if key == nil then
                            return nil, nil
                        end

                        exists = false
                        for i = 1, found_count do
                            if compare(value, found[i]) then
                                exists = true
                                break
                            end
                        end

                        found_count = found_count + 1
                        found[found_count] = value
                    until not exists

                    return key, value
                end, table, key
            end
        else
            enumerator_cache[res] = function()
                local found = {}
                local iterator, table, key = pairs(original)
                return function(t, k)
                    local key = k
                    local value, exists
                    repeat
                        key, value = iterator(t, key)
                        if key == nil then
                            return nil, nil
                        end

                        exists = found[value]

                        found[value] = true
                    until not exists

                    return key, value
                end, table, key
            end
        end

        return res
    end,
    prepend = function(constructor, original, element)
        local res = constructor()

        enumerator_cache[res] = function()
            local single = false
            local dummy_key = {}
            local iterator, table, key = pairs(original)
            return function(t, k)
                if single == false then
                    single = true
                    return dummy_key, element
                end

                return iterator(t, k == dummy_key and key or k)
            end, table, nil
        end

        return res
    end,
    append = function(constructor, original, element)
        local res = constructor()

        enumerator_cache[res] = function()
            local single = false
            local iterator, table, key = pairs(original)
            return function(t, k)
                if single then
                    return nil, nil
                end

                local key, value = iterator(t, k)
                if key == nil then
                    single = true
                    return 0, element
                end

                return key, value
            end, table, key
        end

        return res
    end,
    reverse = function(constructor, original)
        local res = constructor()

        enumerator_cache[res] = function()
            local elements, length = enumerable_to_table(original)
            return function(t, k)
                k = k + 1
                if k > length then
                    return nil, nil
                end

                return k, t[length - k + 1]
            end, elements, 0
        end

        return res
    end,
    zip = function(constructor, original, other, selector)
        local res = constructor()

        if selector then
            enumerator_cache[res] = function()
                local iterator_original, table_original, key_original = pairs(original)
                local iterator_other, table_other, key_other = pairs(other)
                return function(_, k)
                    local value_original, value_other
                    key_original, value_original = iterator_original(table_original, key_original)
                    key_other, value_other = iterator_other(table_other, key_other)
                    if key_original == nil or key_other == nil then
                        return nil, nil
                    end

                    return k + 1, selector(value_original, value_other)
                end, nil, 0
            end
        else
            enumerator_cache[res] = function()
                local iterator_original, table_original, key_original = pairs(original)
                local iterator_other, table_other, key_other = pairs(other)
                return function(_, k)
                    local value_original, value_other
                    key_original, value_original = iterator_original(table_original, key_original)
                    key_other, value_other = iterator_other(table_other, key_other)
                    if key_original == nil or key_other == nil then
                        return nil, nil
                    end

                    return k + 1, {value_original, value_other}
                end, nil, 0
            end
        end

        return res
    end,
    intersect = function(constructor, original, other, compare)
        local res = constructor()

        if compare then
            enumerator_cache[res] = function()
                local iterator, table, key = pairs(original)
                local elements, length = enumerable_to_table(other)
                return function(t, k)
                    local key = k
                    local value, match
                    repeat
                        key, value = iterator(t, key)
                        if key == nil then
                            return nil, nil
                        end

                        match = false
                        for i = 1, length do
                            if compare(value, elements[i]) then
                                match = true
                                break
                            end
                        end
                    until match

                    return key, value
                end, table, key
            end
        else
            enumerator_cache[res] = function()
                local iterator, table, key = pairs(original)
                local elements, length = enumerable_to_table(other)
                return function(t, k)
                    local key = k
                    local value, match
                    repeat
                        key, value = iterator(t, key)
                        if key == nil then
                            return nil, nil
                        end

                        match = false
                        for i = 1, length do
                            if value == elements[i] then
                                match = true
                                break
                            end
                        end
                    until match

                    return key, value
                end, table, key
            end
        end

        return res
    end,
    except = function(constructor, original, other, compare)
        local res = constructor()

        if compare then
            enumerator_cache[res] = function()
                local iterator, table, key = pairs(original)
                local elements, length = enumerable_to_table(other)
                return function(t, k)
                    local key = k
                    local value, match
                    repeat
                        key, value = iterator(t, key)
                        if key == nil then
                            return nil, nil
                        end

                        match = false
                        for i = 1, length do
                            if compare(value, elements[i]) then
                                match = true
                                break
                            end
                        end
                    until not match

                    return key, value
                end, table, key
            end
        else
            enumerator_cache[res] = function()
                local iterator, table, key = pairs(original)
                local elements, length = enumerable_to_table(other)
                return function(t, k)
                    local key = k
                    local value, match
                    repeat
                        key, value = iterator(t, key)
                        if key == nil then
                            return nil, nil
                        end

                        match = false
                        for i = 1, length do
                            if value == elements[i] then
                                match = true
                                break
                            end
                        end
                    until not match

                    return key, value
                end, table, key
            end
        end

        return res
    end,
    union = function(constructor, original, other, compare)
        local res = constructor()

        if compare then
            enumerator_cache[res] = function()
                local found = {}
                local found_count = 0
                local first = true
                local iterator, table, key = pairs(original)
                return function(_, k)
                    local key = k
                    local value, exists
                    repeat
                        key, value = iterator(table, key)
                        if key == nil  then
                            if first then
                                iterator, table, key = pairs(other)
                                exists = true
                                first = false
                            else
                                return nil, nil
                            end
                        else
                            exists = false
                            for i = 1, found_count do
                                if compare(value, found[i]) then
                                    exists = true
                                    break
                                end
                            end

                            found_count = found_count + 1
                            found[found_count] = value
                        end
                    until not exists

                    return key, value
                end, nil, key
            end
        else
            enumerator_cache[res] = function()
                local found = {}
                local found_count = 0
                local first = true
                local iterator, table, key = pairs(original)
                return function(_, k)
                    local key = k
                    local value, exists
                    repeat
                        key, value = iterator(table, key)
                        if key == nil  then
                            if first then
                                iterator, table, key = pairs(other)
                                exists = true
                                first = false
                            else
                                return nil, nil
                            end
                        else
                            exists = false
                            for i = 1, found_count do
                                if value == found[i] then
                                    exists = true
                                    break
                                end
                            end

                            found_count = found_count + 1
                            found[found_count] = value
                        end
                    until not exists

                    return key, value
                end, nil, key
            end
        end

        return res
    end,
}

local build_index_table = function(constructor, converter, add, remove, methods)
    local index_table = {}

    for name, fn in pairs(enumerable) do
        index_table[name] = fn
    end

    for name, fn in pairs(lazy_functions) do
        index_table[name] = function(original, ...)
            return fn(constructor, original, ...)
        end
    end

    index_table.add = add
    index_table.remove = remove
    index_table.copy = function(original, ...)
        local res = constructor()
        for key, el in pairs(original) do
            add(res, el, key)
        end

        return res
    end

    index_table.clear = function(original)
        for key in pairs(original) do
            remove(original, key)
        end
    end

    for name, fn in pairs(methods) do
        index_table[name] = function(original, ...)
            local cached = enumerator_cache[original]
            return fn(cached and converter(cached) or original, ...)
        end
    end

    return index_table
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

local meta_cache = {}

local result_cache = {}
local index_cache = {}
local configure_metatable = function(meta, methods, name)
    -- Create default addition function
    if meta.__add_element == nil then
        meta.__add_element = function(t, v)
            rawset(t, #t + 1, v)
        end
    end

    local add = meta.__add_element

    -- Create default removal function
    if meta.__remove_key == nil then
        meta.__remove_key = function(t, k)
            rawset(t, k, nil)
        end
    end

    local remove = meta.__remove_key

    -- Create value constructor
    if meta.__create == nil then
        meta.__create = function(...)
            return setmetatable({...}, meta)
        end
    end

    local constructor = meta.__create

    -- Create copy constructor
    if meta.__convert == nil then
        meta.__convert = function(t)
            local res = constructor()
            for _, el in pairs(t) do
                add(res, el)
            end
            return res
        end
    end

    local converter = meta.__convert

    local index_table = build_index_table(constructor, converter, add, remove, methods)
    index_cache[index_table] = true

    -- __index
    local original_index = meta.__index
    local index_type = type(original_index)
    local raw_getter
    if index_type == 'nil' then
        raw_getter = function(_, _)
            return nil
        end
    elseif index_type == 'table' then
        raw_getter = function(_, k)
            return original_index[k]
        end
    elseif index_type == 'function' then
        raw_getter = function(t, k)
            return original_index(t, k)
        end
    else
        error('Unknown index_type: ' .. type)
    end

    meta.__index = function(t, k)
        local indexed = index_table[k]
        if indexed then
            return indexed
        end

        if enumerator_cache[t] == nil then
            return raw_getter(t, k)
        end

        local converted = converter(t)
        local original_result = converted[k]
        if type(original_result) == 'function' then
            return function(_, ...)
                return original_result(converted, ...)
            end
        end

        return original_result
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
        local cached = enumerator_cache[t]
        if cached ~= nil then
            return cached()
        end
        return enumerator(t)
    end

    -- Implement toX function as a constructor call
    if name ~= nil then
        local key = 'to_' .. name
        enumerable[key] = converter
        for cached_index_table in pairs(index_cache) do
            cached_index_table[key] = converter
        end
        for cached_result in pairs(result_cache) do
            cached_result[key] = converter
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
                return fn(enumerator_cache[t] and converter(t) or t, ...)
            end
        end
    end
    for _, operator in pairs(operators.binary) do
        local fn = meta[operator]
        if fn ~= nil and is_native(fn) then
            meta[operator] = function(t1, t2, ...)
                return fn(enumerator_cache[t1] and converter(t1) or t1, enumerator_cache[t2] and converter(t2) or t2, ...)
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

    if meta.__serialize_as == nil then
        meta.__serialize_as = function(t)
            local enumerated = {}
            local count = 0
            for _, value in pairs(t) do
                count = count + 1
                enumerated[count] = value
            end
            return enumerated
        end
    end

    meta_cache[meta] = true

    return constructor
end

local empty_meta = {}
empty_constructor = configure_metatable(empty_meta, {})
local empty_converter = empty_meta.__convert

local result = {
    init_type = configure_metatable,
    wrap = function(t)
        --TODO: Or just ignore existing metatable? Or copy? Or initialize fully?
        assert(getmetatable(t) == nil, 'Cannot wrap enumerable around existing metatable')

        return empty_converter(t, {})
    end,
    is_enumerable = function(t)
        local meta = getmetatable(t)
        return meta ~= nil and meta_cache[meta]
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

result_cache[result] = true

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
